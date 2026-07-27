/**
 * Pi Power Tools
 *
 * Background tasks logic ported faithfully from tau (Mearman/tau):
 *   - bash override with 15s auto-background race + Ctrl+B signal backgrounding
 *   - bash_bg / jobs / job_decide tools
 *   - disk-based output (/tmp/pi-bg-<jobId>.log), process-group kill
 *   - stall watchdog (interactive-prompt detection after 45s, kill + notify)
 *   - size watchdog (kill jobs > 100 MiB output)
 *   - tmux backend when available (git repos), direct-spawn fallback
 *   - pill bar + agent-backgrounded status, completion notifications to agent
 *   - Ctrl+B / Ctrl+J / Shift+Down / Ctrl+X shortcuts, /bg /fg /jobs commands
 *
 * Plus original power-tools extras:
 *   - Notifications — OSC 777/99 terminal notifications on agent complete, /notifications
 *   - Git Checkpoints — auto stash create per turn, fork restore prompt
 */

import type {
	AgentToolResult,
	AgentToolUpdateCallback,
} from "@earendil-works/pi-agent-core"
import type {
	ExtensionAPI,
	ExtensionCommandContext,
} from "@earendil-works/pi-coding-agent"
import {
	createBashTool,
	type BashToolDetails,
} from "@earendil-works/pi-coding-agent"
import { StringEnum, Type } from "@earendil-works/pi-ai"
import { spawn, execSync } from "node:child_process"
import {
	closeSync,
	existsSync,
	mkdirSync,
	openSync,
	readFileSync,
	readdirSync,
	readSync,
	statSync,
	unlinkSync,
	writeFileSync,
	chmodSync,
	rmSync,
} from "node:fs"
import { readFile } from "node:fs/promises"
import { join } from "node:path"
import { createHash } from "node:crypto"
import type { ChildProcess } from "node:child_process"

// ─── Types ───────────────────────────────────────────────────

type JobStatus = "running" | "completed" | "failed" | "killed"

interface BackgroundJob {
	id: string
	command: string
	pid: number
	startTime: number
	status: JobStatus
	exitCode?: number
	logPath: string
	proc?: ChildProcess
	toolCallId: string
	donePromise?: Promise<void>
	resolveDone?: () => void
	outputConsumed?: boolean
	isBackgrounded: boolean
}

interface RunningProcess {
	toolCallId: string
	proc: ChildProcess
	command: string
	logPath: string
	triggerBackground: () => void
}

interface UiContext {
	ui: {
		notify(
			message: string,
			level?: "info" | "warning" | "error",
		): void
		setWidget(name: string, content: string[] | undefined): void
		setStatus(name: string, content: unknown): void
		theme: { fg(colour: string, text: string): string }
		select(title: string, options: string[]): Promise<string | undefined>
		editor(title: string, content: string): Promise<string | undefined>
	}
}

interface TmuxJobContext {
	session: string
	windowId: string
	exitCodeFile: string
	outputFile: string
	gitRoot: string
}

interface BgState {
	backgroundJobs: Map<string, BackgroundJob>
	runningProcesses: Map<string, RunningProcess>
	jobCounter: number
	currentlyRunningToolCallId: string | null
	agentBackgrounded: boolean
	pendingDecisionJobId: string | undefined
	tmuxAvailable: boolean
	nonInteractive: boolean
	completedJobCount: number
	failedJobCount: number
	recentTerminalJobs: BackgroundJob[]
}

// ─── Constants ───────────────────────────────────────────────

const DEFAULT_TIMEOUT_MS = 15_000
const STALL_CHECK_INTERVAL_MS = 5_000
const STALL_THRESHOLD_MS = 45_000
const STALL_TAIL_BYTES = 1024
const MAX_OUTPUT_PREVIEW_CHARS = 12_000
const MAX_LOG_BYTES = 100 * 1024 * 1024 // 100 MiB
const NOTIFICATION_BODY_MAX = 200
const PILL_INTERVAL = 2_000

const DISALLOWED_AUTO_BACKGROUND_COMMANDS = ["sleep"]

const PROMPT_PATTERNS = [
	/\(y\/n\)/i,
	/\[y\/n\]/i,
	/\(yes\/no\)/i,
	/\b(?:Do you|Would you|Shall I|Are you sure|Ready to)\b.*\? *$/i,
	/Press (any key|Enter)/i,
	/Continue\?/i,
	/Overwrite\?/i,
]

// ─── Utils helpers (ported from tau/src/utils.ts) ────────────

function killProcessGroup(
	pid: number,
	signal: NodeJS.Signals = "SIGTERM",
): void {
	try {
		process.kill(-pid, signal)
	} catch {
		try {
			process.kill(pid, signal)
		} catch {
			/* already dead */
		}
	}
}

function generateJobId(counter: number, pid: number = process.pid): string {
	return `job-${pid}-${counter}`
}

function logPathForJob(jobId: string): string {
	return `/tmp/pi-bg-${jobId}.log`
}

function createJobDonePromise(job: BackgroundJob): void {
	let resolveDone: (() => void) | undefined
	job.donePromise = new Promise<void>((resolve) => {
		resolveDone = resolve
	})
	job.resolveDone = resolveDone
}

function markJobTerminal(
	job: BackgroundJob,
	status: JobStatus,
	exitCode?: number,
): void {
	if (
		job.status === "completed" ||
		job.status === "failed" ||
		job.status === "killed"
	) {
		return
	}
	job.status = status
	job.exitCode = exitCode
	delete job.proc
	if (job.resolveDone) {
		job.resolveDone()
		delete job.resolveDone
	}
}

function formatDuration(ms: number): string {
	const totalSecs = Math.floor(ms / 1000)
	const mins = Math.floor(totalSecs / 60)
	const secs = totalSecs % 60
	return mins > 0 ? `${mins}m${secs}s` : `${secs}s`
}

function formatJobLine(job: BackgroundJob): string {
	const duration = formatDuration(Date.now() - job.startTime)
	const status =
		job.status === "running"
			? job.isBackgrounded
				? `◐ running (${duration})`
				: `▶ running (${duration})`
			: job.status === "completed"
			  ? "✅ completed"
			  : job.status === "failed"
			    ? "❌ failed"
			    : "🛑 killed"
	return `${job.id}: ${job.command.slice(0, 80)} - ${status}`
}

async function readOutputTail(
	path: string,
	maxChars: number,
): Promise<string> {
	try {
		const content = await readFile(path, "utf-8")
		if (content.length <= maxChars) return content
		return `...[truncated, showing last ${maxChars} chars]\n${content.slice(-maxChars)}`
	} catch {
		return "(no output yet)"
	}
}

function readOutputTailSync(path: string, maxChars: number): string {
	try {
		const { size } = statSync(path)
		if (size === 0) return "(no output yet)"
		const fd = openSync(path, "r")
		try {
			const readStart = Math.max(0, size - maxChars)
			const toRead = Math.min(size, maxChars)
			const buf = Buffer.alloc(toRead)
			readSync(fd, buf, 0, toRead, readStart)
			const content = buf.toString("utf-8", 0, toRead)
			if (size <= maxChars) return content
			return `...[truncated, showing last ${maxChars} chars]\n${content}`
		} finally {
			closeSync(fd)
		}
	} catch {
		return "(no output yet)"
	}
}

function looksLikePrompt(tail: string): boolean {
	const lastLine = tail.trimEnd().split("\n").pop() ?? ""
	return PROMPT_PATTERNS.some((p) => p.test(lastLine))
}

function isAutoBackgroundAllowed(command: string): boolean {
	const base = command.trim().split(/\s+/)[0] ?? ""
	return !DISALLOWED_AUTO_BACKGROUND_COMMANDS.includes(base)
}

function detectBlockedSleep(command: string): string | null {
	const first =
		command
			.trim()
			.split(/&&|;|\|/)[0]
			?.trim() ?? ""
	const m = /^sleep\s+(\d+(?:\.\d+)?)\s*$/.exec(first)
	if (!m) return null
	const secs = parseFloat(m[1])
	if (secs < 2) return null
	return first
}

function detectNonInteractive(
	argv: readonly string[],
	stdinIsTTY: boolean,
): boolean {
	if (!stdinIsTTY) return true
	return argv.includes("-p") || argv.includes("--print")
}

function cleanupStaleLogs(): void {
	const MAX_AGE_MS = 24 * 60 * 60 * 1000
	try {
		const entries = readdirSync("/tmp")
		const now = Date.now()
		for (const entry of entries) {
			if (!entry.startsWith("pi-bg-")) continue
			const filePath = `/tmp/${entry}`
			try {
				const { mtimeMs } = statSync(filePath)
				if (now - mtimeMs > MAX_AGE_MS) {
					unlinkSync(filePath)
				}
			} catch {
				/* file already gone */
			}
		}
	} catch {
		/* /tmp not accessible */
	}
}

// ─── Tmux helpers (ported from tau/src/tmux.ts) ──────────────

let cachedTmuxAvailable: boolean | undefined

function isTmuxAvailable(): boolean {
	if (cachedTmuxAvailable !== undefined) return cachedTmuxAvailable
	try {
		execSync("which tmux 2>/dev/null", {
			encoding: "utf-8",
			timeout: 3000,
			stdio: "pipe",
		})
		cachedTmuxAvailable = true
	} catch {
		cachedTmuxAvailable = false
	}
	return cachedTmuxAvailable
}

function shellQuote(value: string): string {
	return `'${value.replace(/'/g, `'\\''`)}'`
}

function sessionNameForGitRoot(gitRoot: string): string {
	const slug =
		gitRoot.split("/").pop()?.slice(0, 16).toLowerCase() ?? "project"
	const hash = createHash("md5").update(gitRoot).digest("hex").slice(0, 8)
	return `pi-bg-${slug}-${hash}`
}

function tmuxExecSafe(cmd: string): string | null {
	try {
		return execSync(cmd, {
			encoding: "utf-8",
			timeout: 10_000,
			stdio: ["ignore", "pipe", "pipe"],
		}).trim()
	} catch {
		return null
	}
}

function tmuxExec(cmd: string): string {
	return execSync(cmd, {
		encoding: "utf-8",
		timeout: 10_000,
		stdio: ["ignore", "pipe", "pipe"],
	}).trim()
}

function sessionExists(name: string): boolean {
	return (
		tmuxExecSafe(
			`tmux has-session -t ${shellQuote(name)} 2>/dev/null && echo yes`,
		) === "yes"
	)
}

function runDirPath(): string {
	const dir = `/tmp/pi-tmux-${process.pid}`
	mkdirSync(dir, { recursive: true, mode: 0o700 })
	return dir
}

function createBashScript(
	runDir: string,
	session: string,
	command: string,
	paths: { id: string; outputFile: string; exitCodeFile: string },
): { scriptPath: string } {
	const scriptDir = join(runDir, "s")
	mkdirSync(scriptDir, { recursive: true, mode: 0o700 })
	chmodSync(scriptDir, 0o700)

	const scriptPath = join(scriptDir, `${session}.${paths.id}.sh`)
	const { exitCodeFile, outputFile } = paths

	writeFileSync(
		scriptPath,
		`#!/usr/bin/env bash
__output_file=${shellQuote(outputFile)}
__exit_code_file=${shellQuote(exitCodeFile)}
(
${command}
) >> "$__output_file" 2>&1
printf '%s\\n' "$?" > "$__exit_code_file"
`,
		{ mode: 0o755 },
	)

	return { scriptPath }
}

function spawnInTmux(
	command: string,
	cwd: string,
	runDir: string,
	session: string,
): { windowId: string; id: string; outputFile: string; exitCodeFile: string } {
	const exists = sessionExists(session)

	const id = `${process.pid}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 6)}`
	const exitCodeFile = join(runDir, `${session}.${id}.exit`)
	const outputFile = join(runDir, `${session}.${id}.out`)

	const script = createBashScript(runDir, session, command, {
		id,
		outputFile,
		exitCodeFile,
	})

	const createCmd = exists
		? `new-window -d -t ${shellQuote(session)}`
		: `new-session -d -s ${shellQuote(session)}`

	const windowName = command.split(/\s/)[0]?.slice(0, 30) ?? "shell"
	const windowId = tmuxExec(
		`tmux ${createCmd} -n ${shellQuote(windowName)} -c ${shellQuote(cwd)} -P -F '#{window_id}' ${shellQuote(script.scriptPath)}`,
	)

	return { windowId, id, outputFile, exitCodeFile }
}

function captureOutput(
	windowId: string,
	lines: number,
	outputFile?: string,
): string {
	if (outputFile && existsSync(outputFile)) {
		const content = readFileSync(outputFile, "utf-8")
		if (content.length > 0) return content
	}
	const raw = tmuxExecSafe(
		`tmux capture-pane -t ${shellQuote(windowId)} -p -S -${lines}`,
	)
	return raw ?? "(no output)"
}

function checkExitCode(exitCodeFile: string): number | undefined {
	if (!existsSync(exitCodeFile)) return undefined
	const content = readFileSync(exitCodeFile, "utf-8").trim()
	const code = parseInt(content)
	if (!Number.isFinite(code)) return undefined
	try {
		unlinkSync(exitCodeFile)
	} catch {
		/* already gone */
	}
	return code
}

function killWindow(windowId: string): void {
	tmuxExecSafe(`tmux kill-window -t ${shellQuote(windowId)}`)
}

function getGitRoot(cwd: string): string | null {
	try {
		return execSync("git rev-parse --show-toplevel", {
			cwd,
			encoding: "utf-8",
			timeout: 5000,
		}).trim()
	} catch {
		return null
	}
}

function cleanupStaleTmuxRunDirs(): void {
	const entries = readdirSync("/tmp").filter((e) => e.startsWith("pi-tmux-"))
	for (const entry of entries) {
		const pid = parseInt(entry.replace("pi-tmux-", ""), 10)
		if (pid === process.pid) continue
		try {
			process.kill(pid, 0)
			continue
		} catch {
			/* dead — clean up */
		}
		const dir = join("/tmp", entry)
		try {
			rmSync(dir, { recursive: true, force: true })
		} catch {
			/* permission error or concurrent cleanup */
		}
	}
	try {
		const sessions = execSync("tmux list-sessions -F '#{session_name}'", {
			encoding: "utf-8",
			timeout: 3000,
			stdio: ["ignore", "pipe", "pipe"],
		})
			.trim()
			.split("\n")
			.filter((s) => s.startsWith("pi-bg-"))
		for (const session of sessions) {
			const panePids = execSync(
				`tmux list-panes -t ${session} -F '#{pane_pid}'`,
				{
					encoding: "utf-8",
					timeout: 3000,
					stdio: ["ignore", "pipe", "pipe"],
				},
			)
				.trim()
				.split("\n")
				.map((p) => parseInt(p, 10))
			const allDead = panePids.every((pid) => {
				try {
					process.kill(pid, 0)
					return false
				} catch {
					return true
				}
			})
			if (allDead) {
				execSync(`tmux kill-session -t ${session}`, {
					timeout: 3000,
					stdio: "ignore",
				})
			}
		}
	} catch {
		/* tmux not available or no sessions */
	}
}

// ─── Bash-tmux helpers (ported from tau/src/features/bash-tmux.ts) ──

function attachTmuxContext(job: BackgroundJob, ctx: TmuxJobContext): void {
	;(job as unknown as { tmux: TmuxJobContext }).tmux = ctx
}

function getTmuxContext(job: BackgroundJob): TmuxJobContext | undefined {
	return (job as unknown as { tmux?: TmuxJobContext }).tmux
}

function pollTmuxCompletion(job: BackgroundJob): {
	completed: boolean
	exitCode?: number
} {
	const ctx = getTmuxContext(job)
	if (!ctx) return { completed: false }
	const code = checkExitCode(ctx.exitCodeFile)
	if (code === undefined) return { completed: false }
	return { completed: true, exitCode: code }
}

function killTmuxJob(job: BackgroundJob): void {
	const ctx = getTmuxContext(job)
	if (ctx) killWindow(ctx.windowId)
}

function readTmuxOutput(
	job: BackgroundJob,
	maxChars: number,
): Promise<string> {
	const ctx = getTmuxContext(job)
	if (ctx) {
		const output = captureOutput(ctx.windowId, 2000, ctx.outputFile)
		if (output.length <= maxChars) return Promise.resolve(output)
		return Promise.resolve(
			`...[truncated, showing last ${maxChars} chars]\n${output.slice(-maxChars)}`,
		)
	}
	return readOutputTail(job.logPath, maxChars)
}

function spawnForegroundTmux(
	command: string,
	cwd: string,
): {
	tmuxCtx: TmuxJobContext
	logPath: string
} {
	const gitRoot = getGitRoot(cwd)
	if (!gitRoot) {
		throw new Error(
			"Not in a git repository — tmux backend requires a git root for session naming.",
		)
	}

	const session = sessionNameForGitRoot(gitRoot)
	const runDir = runDirPath()
	const result = spawnInTmux(command, cwd, runDir, session)
	const logPath = result.outputFile

	return {
		tmuxCtx: {
			session,
			windowId: result.windowId,
			exitCodeFile: result.exitCodeFile,
			outputFile: result.outputFile,
			gitRoot,
		},
		logPath,
	}
}

function notifyTmuxCompletion(
	job: BackgroundJob,
	state: BgState,
	pi: ExtensionAPI,
	ctx: UiContext,
): void {
	if (job.outputConsumed) {
		const tmuxCtx = getTmuxContext(job)
		if (tmuxCtx) killWindow(tmuxCtx.windowId)
		state.backgroundJobs.delete(job.id)
		if (job.status === "completed") state.completedJobCount++
		if (job.status === "failed") state.failedJobCount++
		state.recentTerminalJobs.push(job)
		if (state.recentTerminalJobs.length > 20)
			state.recentTerminalJobs.shift()
		return
	}

	const durationText = formatDuration(Date.now() - job.startTime)
	const emoji = job.status === "completed" ? "✅" : "❌"
	const statusText = `Background ${job.id} ${job.status} (${durationText})`
	const exitCodeText =
		job.exitCode !== undefined ? `\nExit code: ${job.exitCode}` : ""

	ctx.ui.notify(
		statusText,
		job.status === "completed" ? "info" : "error",
	)

	pi.sendMessage(
		{
			customType: "job-completion",
			content:
				`${emoji} ${statusText}\n` +
				`Command: ${job.command}\n` +
				`Output: ${job.logPath}${exitCodeText}`,
			display: true,
			details: {
				jobId: job.id,
				status: job.status,
				exitCode: job.exitCode,
				duration: durationText,
				command: job.command,
				logPath: job.logPath,
			},
		},
		{ deliverAs: "followUp", triggerTurn: true },
	)

	const tmuxCtx = getTmuxContext(job)
	if (tmuxCtx) killWindow(tmuxCtx.windowId)

	state.backgroundJobs.delete(job.id)
	if (job.status === "completed") state.completedJobCount++
	if (job.status === "failed") state.failedJobCount++
	state.recentTerminalJobs.push(job)
	if (state.recentTerminalJobs.length > 20)
		state.recentTerminalJobs.shift()
}

function spawnBackgroundTmux(
	command: string,
	cwd: string,
	toolCallId: string,
	state: BgState,
	pi: ExtensionAPI,
	ctx: UiContext,
	onStartStallWatchdog: (
		jobId: string,
		command: string,
		logPath: string,
	) => () => void,
): BackgroundJob {
	const { tmuxCtx, logPath } = spawnForegroundTmux(command, cwd)

	const jobId = `tmux-${process.pid}-${++state.jobCounter}`
	const job: BackgroundJob = {
		id: jobId,
		command,
		pid: -1,
		startTime: Date.now(),
		status: "running",
		logPath,
		toolCallId,
		isBackgrounded: true,
	}
	createJobDonePromise(job)
	attachTmuxContext(job, tmuxCtx)
	state.backgroundJobs.set(jobId, job)

	const cancelStall = onStartStallWatchdog(jobId, command, logPath)

	const pollTimer = setInterval(() => {
		const result = pollTmuxCompletion(job)
		if (!result.completed) return

		clearInterval(pollTimer)
		cancelStall()
		markJobTerminal(
			job,
			result.exitCode === 0 || result.exitCode === null
				? "completed"
				: "failed",
			result.exitCode ?? 0,
		)
		notifyTmuxCompletion(job, state, pi, ctx)
	}, 500)
	pollTimer.unref()

	return job
}

// ─── Background helpers (ported from tau/src/features/background.ts) ──

function silenceJobAfterKill(job: BackgroundJob): void {
	markJobTerminal(job, "killed")
	job.outputConsumed = true
}

function startStallWatchdog(
	jobId: string,
	command: string,
	logPath: string,
	pi: ExtensionAPI,
	onOversize?: () => void,
): () => void {
	let lastSize = 0
	let lastGrowth = Date.now()
	let cancelled = false

	const timer = setInterval(() => {
		if (cancelled) return
		try {
			const size = statSync(logPath).size

			if (size > MAX_LOG_BYTES) {
				cancelled = true
				clearInterval(timer)
				if (onOversize) onOversize()
				pi.sendMessage(
					{
						customType: "bg-stall",
						content: `⚠️ Background job ${jobId} exceeded ${MAX_LOG_BYTES / (1024 * 1024)} MiB output. Terminated.`,
						display: true,
						details: { jobId, logPath, command },
					},
					{ deliverAs: "followUp", triggerTurn: true },
				)
				return
			}

			if (size > lastSize) {
				lastSize = size
				lastGrowth = Date.now()
				return
			}
			if (Date.now() - lastGrowth < STALL_THRESHOLD_MS) return

			const tail = readOutputTailSync(logPath, STALL_TAIL_BYTES)
			if (!looksLikePrompt(tail)) {
				lastGrowth = Date.now()
				return
			}

			cancelled = true
			clearInterval(timer)

			const summary =
				`Background job ${jobId} appears to be waiting for interactive input.\n` +
				`Command: ${command}\n\n` +
				`Last output:\n${tail.trimEnd()}\n\n` +
				`The command is likely blocked on an interactive prompt. Kill this job and re-run ` +
				`with piped input (e.g., \`echo y | command\`) or a non-interactive flag.`

			pi.sendMessage(
				{
					customType: "bg-stall",
					content: `⚠️ ${summary}`,
					display: true,
					details: { jobId, logPath, command },
				},
				{ deliverAs: "followUp", triggerTurn: true },
			)
		} catch {
			// File may not exist yet — skip this tick
		}
	}, STALL_CHECK_INTERVAL_MS)

	timer.unref()
	return () => {
		cancelled = true
		clearInterval(timer)
	}
}

function updateWidget(state: BgState, ctx: UiContext): void {
	const allJobs = Array.from(state.backgroundJobs.values())
	const runningJobs = allJobs.filter((job) => job.status === "running")

	if (runningJobs.length === 0 && !state.agentBackgrounded) {
		ctx.ui.setWidget("background-jobs", undefined)
		ctx.ui.setStatus("background-jobs", undefined)
		return
	}

	const pills: string[] = []
	if (state.agentBackgrounded) {
		pills.push("◐ agent (backgrounded)")
	}
	for (const job of runningJobs) {
		const duration = formatDuration(Date.now() - job.startTime)
		const icon = job.isBackgrounded ? "◐" : "▶"
		pills.push(
			`${icon} ${job.id}: ${job.command.slice(0, 25)} (${duration})`,
		)
	}
	ctx.ui.setWidget("background-jobs", pills)

	let statusText = `${runningJobs.length} running`
	if (state.completedJobCount > 0)
		statusText += `, ${state.completedJobCount} done`
	if (state.failedJobCount > 0)
		statusText += `, ${state.failedJobCount} failed`

	ctx.ui.setStatus(
		"background-jobs",
		ctx.ui.theme.fg("accent", `◐ ${statusText}`),
	)
}

function lookupJob(
	state: BgState,
	jobId: string,
): BackgroundJob | undefined {
	return (
		state.backgroundJobs.get(jobId) ??
		state.backgroundJobs.get(`job-${jobId}`) ??
		state.recentTerminalJobs.find(
			(j) => j.id === jobId || j.id === `job-${jobId}`,
		)
	)
}

function clearPendingDecision(state: BgState, job: BackgroundJob): void {
	if (state.pendingDecisionJobId === job.id)
		state.pendingDecisionJobId = undefined
}

const MAX_RECENT_TERMINAL = 20

function removeJob(state: BgState, job: BackgroundJob): void {
	state.backgroundJobs.delete(job.id)
	if (state.pendingDecisionJobId === job.id) {
		state.pendingDecisionJobId = undefined
	}
	if (job.status === "completed") state.completedJobCount++
	if (job.status === "failed") state.failedJobCount++
	state.recentTerminalJobs.push(job)
	if (state.recentTerminalJobs.length > MAX_RECENT_TERMINAL) {
		state.recentTerminalJobs.shift()
	}
}

function notifyCompletion(
	job: BackgroundJob,
	state: BgState,
	pi: ExtensionAPI,
	ctx: UiContext,
): void {
	if (job.outputConsumed) {
		removeJob(state, job)
		return
	}
	const duration = formatDuration(Date.now() - job.startTime)
	const emoji = job.status === "completed" ? "✅" : "❌"
	const statusText = `Background ${job.id} ${job.status} (${duration})`
	const exitCodeText =
		job.exitCode !== undefined ? `\nExit code: ${job.exitCode}` : ""

	ctx.ui.notify(
		statusText,
		job.status === "completed" ? "info" : "error",
	)

	pi.sendMessage(
		{
			customType: "job-completion",
			content:
				`${emoji} ${statusText}\n` +
				`Command: ${job.command}\n` +
				`Output: ${job.logPath}${exitCodeText}`,
			display: true,
			details: {
				jobId: job.id,
				status: job.status,
				exitCode: job.exitCode,
				duration,
				command: job.command,
				logPath: job.logPath,
			},
		},
		{ deliverAs: "followUp", triggerTurn: true },
	)

	removeJob(state, job)
}

function registerBackgroundJob(
	proc: ChildProcess,
	logPath: string,
	command: string,
	toolCallId: string,
	state: BgState,
	pi: ExtensionAPI,
	ctx: UiContext,
): BackgroundJob {
	const jobId = generateJobId(++state.jobCounter)

	const job: BackgroundJob = {
		id: jobId,
		command,
		pid: proc.pid!,
		startTime: Date.now(),
		status: "running",
		logPath,
		proc,
		toolCallId,
		isBackgrounded: true,
	}
	createJobDonePromise(job)

	const existingJob = state.backgroundJobs.get(jobId)
	if (existingJob) {
		existingJob.isBackgrounded = true
	} else {
		state.backgroundJobs.set(jobId, job)
	}
	state.currentlyRunningToolCallId = null

	const cancelStall = startStallWatchdog(jobId, command, logPath, pi, () => {
		if (proc.pid) killProcessGroup(proc.pid, "SIGTERM")
		silenceJobAfterKill(job)
	})

	proc.on("close", (code) => {
		cancelStall()
		markJobTerminal(
			job,
			code === 0 || code === null ? "completed" : "failed",
			code ?? 0,
		)
		clearPendingDecision(state, job)
		notifyCompletion(job, state, pi, ctx)
		updateWidget(state, ctx)
	})

	ctx.ui.notify(`Process backgrounded as ${jobId}`, "info")
	updateWidget(state, ctx)

	return job
}

function startTimeoutTimer(
	triggerBackground: () => void,
	command: string,
	state: BgState,
	toolCallId: string,
	explicitTimeoutMs?: number,
): NodeJS.Timeout {
	const timeoutMs = explicitTimeoutMs ?? DEFAULT_TIMEOUT_MS

	const timer = setTimeout(() => {
		if (state.nonInteractive) return
		if (!state.runningProcesses.has(toolCallId)) return

		if (!isAutoBackgroundAllowed(command)) {
			const rp = state.runningProcesses.get(toolCallId)
			if (rp?.proc.pid) killProcessGroup(rp.proc.pid, "SIGTERM")
			return
		}

		triggerBackground()
	}, timeoutMs)
	timer.unref()
	return timer
}

// ─── Tmux foreground execution ──────────────────────────────

async function executeTmuxForeground(
	toolCallId: string,
	command: string,
	params: Record<string, unknown>,
	signal: AbortSignal | undefined,
	onUpdate: AgentToolUpdateCallback<BashToolDetails | undefined> | undefined,
	ctx: { cwd: string } & UiContext,
	state: BgState,
	pi: ExtensionAPI,
): Promise<AgentToolResult<BashToolDetails | undefined>> {
	const jobId = `tmux-${process.pid}-${++state.jobCounter}`
	let logPath: string
	let tmuxCtx: TmuxJobContext

	try {
		const result = spawnForegroundTmux(command, ctx.cwd)
		logPath = result.logPath
		tmuxCtx = result.tmuxCtx
	} catch {
		state.jobCounter--
		throw new Error(
			"tmux backend requires a git repository. Falling back to direct process management.",
		)
	}

	const job: BackgroundJob = {
		id: jobId,
		command,
		pid: -1,
		startTime: Date.now(),
		status: "running",
		logPath,
		toolCallId,
		isBackgrounded: false,
	}
	createJobDonePromise(job)
	attachTmuxContext(job, tmuxCtx)
	state.backgroundJobs.set(jobId, job)

	let backgroundResolve: (() => void) | null = null
	const backgroundSignal = new Promise<void>((resolve) => {
		backgroundResolve = resolve
	})

	function triggerBackground(): void {
		backgroundResolve?.()
	}

	state.runningProcesses.set(toolCallId, {
		toolCallId,
		proc: { pid: -1 } as never,
		command,
		logPath,
		triggerBackground,
	})
	state.currentlyRunningToolCallId = toolCallId

	if (signal) {
		signal.addEventListener("abort", () => {
			killTmuxJob(job)
		})
	}

	const timeoutMs =
		typeof params.timeout === "number"
			? params.timeout * 1_000
			: DEFAULT_TIMEOUT_MS
	const timer = setTimeout(() => {
		if (state.nonInteractive) return
		if (!state.runningProcesses.has(toolCallId)) return
		if (!isAutoBackgroundAllowed(command)) {
			killTmuxJob(job)
			return
		}
		triggerBackground()
	}, timeoutMs)
	timer.unref()

	const hintTimer = setTimeout(() => {
		ctx.ui.notify("⏱ Ctrl+B to background", "info")
	}, 2_000)
	hintTimer.unref()

	const PROGRESS_POLL_MS = 1_000
	let pollTimer: NodeJS.Timeout | undefined
	const startPolling = (): void => {
		pollTimer = setInterval(() => {
			try {
				const content = readOutputTailSync(logPath, 4_096)
				if (content && content !== "(no output yet)") {
					onUpdate?.({
						content: [{ type: "text" as const, text: content }],
						details: undefined,
					})
				}
			} catch {
				/* File may not be readable yet */
			}
		}, PROGRESS_POLL_MS)
		pollTimer.unref()
	}

	const completionPromise = new Promise<number | null>((resolve) => {
		const check = setInterval(() => {
			const code = checkExitCode(tmuxCtx.exitCodeFile)
			if (code !== undefined) {
				clearInterval(check)
				resolve(code)
			}
		}, 200)
		check.unref()
	})

	try {
		const initialResult = await Promise.race([
			completionPromise,
			new Promise<null>((resolve) => {
				const t = setTimeout(
					resolve,
					2_000,
				) as unknown as NodeJS.Timeout
				t.unref()
			}),
		])

		if (initialResult !== null) {
			state.backgroundJobs.delete(jobId)
			const output = captureOutput(
				tmuxCtx.windowId,
				2000,
				tmuxCtx.outputFile,
			)
			killWindow(tmuxCtx.windowId)
			if (initialResult !== 0 && initialResult !== null) {
				throw new Error(
					output || `Command exited with code ${initialResult}`,
				)
			}
			return {
				content: [
					{ type: "text" as const, text: output || "(no output)" },
				],
				details: undefined,
			}
		}

		startPolling()

		const raceResult = await Promise.race([
			completionPromise.then((code) => ({
				type: "completed" as const,
				code,
			})),
			backgroundSignal.then(() => ({
				type: "backgrounded" as const,
				code: undefined as number | undefined,
			})),
		])

		if (raceResult.type === "backgrounded") {
			clearInterval(pollTimer)
			clearTimeout(timer)
			clearTimeout(hintTimer)
			state.runningProcesses.delete(toolCallId)

			job.isBackgrounded = true
			state.currentlyRunningToolCallId = null

			startStallWatchdog(jobId, command, logPath, pi, () => {
				killTmuxJob(job)
			})

			const bgPoller = setInterval(() => {
				const result = pollTmuxCompletion(job)
				if (!result.completed) return
				clearInterval(bgPoller)
				markJobTerminal(
					job,
					result.exitCode === 0 || result.exitCode === null
						? "completed"
						: "failed",
					result.exitCode ?? 0,
				)
				notifyTmuxCompletion(job, state, pi, ctx)
				updateWidget(state, ctx)
			}, 500)
			bgPoller.unref()

			state.pendingDecisionJobId = jobId

			const duration = formatDuration(timeoutMs)
			pi.sendMessage(
				{
					customType: "bg-timeout",
					content:
						`⏰ Command timed out after ${duration} and has been backgrounded as ${jobId}.\n` +
						`Command: ${command}\n` +
						`Tmux window: ${tmuxCtx.windowId}\n` +
						`Output so far: ${logPath}\n\n` +
						`Use the job_decide tool with jobId "${jobId}" to decide:\n` +
						`- decision "check": inspect the output first\n` +
						`- decision "keep": let it continue running\n` +
						`- decision "kill": terminate it\n\n` +
						`You can attach to the tmux window with: tmux attach -t ${tmuxCtx.windowId}`,
					display: true,
					details: { jobId, logPath, command },
				},
				{ deliverAs: "followUp", triggerTurn: true },
			)

			updateWidget(state, ctx)

			return {
				content: [
					{
						type: "text" as const,
						text: `Process backgrounded as ${jobId}\nCommand: ${command}\nTmux window: ${tmuxCtx.windowId}\nOutput: ${logPath}`,
					},
				],
				details: undefined,
			}
		}

		clearInterval(pollTimer)
		clearTimeout(timer)
		clearTimeout(hintTimer)
		state.runningProcesses.delete(toolCallId)
		if (state.currentlyRunningToolCallId === toolCallId) {
			state.currentlyRunningToolCallId = null
		}
		state.backgroundJobs.delete(jobId)

		const output = captureOutput(
			tmuxCtx.windowId,
			2000,
			tmuxCtx.outputFile,
		)
		killWindow(tmuxCtx.windowId)

		if (raceResult.code !== 0 && raceResult.code !== null) {
			throw new Error(
				output || `Command exited with code ${raceResult.code}`,
			)
		}

		return {
			content: [
				{ type: "text" as const, text: output || "(no output)" },
			],
			details: undefined,
		}
	} finally {
		clearInterval(pollTimer)
		clearTimeout(timer)
		clearTimeout(hintTimer)
	}
}

// ─── Background tools registration ──────────────────────────

function registerBackgroundJobs(pi: ExtensionAPI, state: BgState): void {
	// ── Override bash tool ─────────────────────────────────────────────

	const originalBashTool = createBashTool(process.cwd())

	pi.registerTool({
		...originalBashTool,
		name: "bash",
		description:
			"Execute bash commands with streaming output. Commands that run longer than 15 seconds " +
			"are automatically backgrounded and the agent is asked whether to kill or let them continue. " +
			"Use Ctrl+B to manually background a running process. " +
			"Background job output is written to per-session log files.",
		promptSnippet:
			"Execute shell commands (backgroundable with Ctrl+B)",
		promptGuidelines: [
			"Use bash_bg when you know a command should run in background from the start.",
			"Use the jobs tool with action 'list' to check background job status.",
			"Use the jobs tool with action 'output' to read a background job's output file.",
		],

		async execute(
			toolCallId,
			params,
			signal,
			onUpdate,
			ctx,
		): Promise<AgentToolResult<BashToolDetails | undefined>> {
			const { command } = params
			const uiCtx: UiContext = ctx as unknown as UiContext

			const sleepMatch = detectBlockedSleep(command)
			if (sleepMatch) {
				throw new Error(
					`Blocked: ${sleepMatch}. Use bash_bg for long waits. ` +
						"For pacing < 2s, sleep is fine.",
				)
			}

			// ── Tmux path ─────────────────────────────────────────────
			if (state.tmuxAvailable) {
				try {
					return await executeTmuxForeground(
						toolCallId,
						command,
						params,
						signal,
						onUpdate,
						{ cwd: ctx.cwd, ...uiCtx },
						state,
						pi,
					)
				} catch {
					// tmux spawn failed — fall through to direct-spawn path.
				}
			}

			// ── Direct spawn path (fallback when tmux unavailable) ───
			const jobId = generateJobId(++state.jobCounter)
			const logPath = logPathForJob(jobId)
			mkdirSync(join(logPath, ".."), { recursive: true })

			const logFd = openSync(logPath, "w")
			const proc = spawn("bash", ["-c", command], {
				stdio: ["pipe", logFd, logFd],
				cwd: ctx.cwd,
				detached: true,
				env: { ...process.env },
			})
			closeSync(logFd)

			if (!proc.pid) {
				throw new Error("Failed to spawn process")
			}

			let backgroundResolve: (() => void) | null = null
			const backgroundSignal = new Promise<void>((resolve) => {
				backgroundResolve = resolve
			})

			function triggerBackground(): void {
				backgroundResolve?.()
			}

			const rp: RunningProcess = {
				toolCallId,
				proc,
				command,
				logPath,
				triggerBackground,
			}
			state.runningProcesses.set(toolCallId, rp)
			state.currentlyRunningToolCallId = toolCallId

			state.backgroundJobs.set(jobId, {
				id: jobId,
				command,
				pid: proc.pid,
				startTime: Date.now(),
				status: "running",
				logPath,
				proc,
				toolCallId,
				isBackgrounded: false,
			})

			const procResult = new Promise<{
				code: number | null
				interrupted: boolean
			}>((resolve) => {
				proc.on("close", (code) => {
					resolve({
						code,
						interrupted: code === 137 || code === 143,
					})
				})
				proc.on("error", () => {
					resolve({ code: 1, interrupted: false })
				})
			})

			if (signal) {
				signal.addEventListener("abort", () => {
					killProcessGroup(proc.pid!, "SIGTERM")
				})
			}

			const timer = startTimeoutTimer(
				triggerBackground,
				command,
				state,
				toolCallId,
				typeof params.timeout === "number"
					? params.timeout * 1_000
					: undefined,
			)

			const hintTimer = setTimeout(() => {
				uiCtx.ui.notify("⏱ Ctrl+B to background", "info")
			}, 2_000)
			hintTimer.unref()

			const PROGRESS_POLL_MS = 1_000
			let pollTimer: NodeJS.Timeout | undefined
			const startPolling = (): void => {
				pollTimer = setInterval(() => {
					try {
						const content = readOutputTailSync(logPath, 4_096)
						if (content && content !== "(no output yet)") {
							onUpdate?.({
								content: [
									{ type: "text" as const, text: content },
								],
								details: undefined,
							})
						}
					} catch {
						/* File may not be readable yet */
					}
				}, PROGRESS_POLL_MS)
				pollTimer.unref()
			}

			try {
				const initialResult = await Promise.race([
					procResult,
					new Promise<null>((resolve) => {
						const t = setTimeout(
							resolve,
							2_000,
						) as unknown as NodeJS.Timeout
						t.unref()
					}),
				])

				if (initialResult !== null) {
					state.backgroundJobs.delete(jobId)
					const output = await readFile(logPath, "utf-8").catch(
						() => "",
					)
					return {
						content: [
							{
								type: "text" as const,
								text: output || "(no output)",
							},
						],
						details: undefined,
					}
				}

				startPolling()

				const raceResult = await Promise.race([
					procResult.then((r) => ({
						type: "completed" as const,
						...r,
					})),
					backgroundSignal.then(() => ({
						type: "backgrounded" as const,
					})),
				])

				if (raceResult.type === "backgrounded") {
					clearInterval(pollTimer)
					clearTimeout(timer)
					clearTimeout(hintTimer)
					state.runningProcesses.delete(toolCallId)

					const job = registerBackgroundJob(
						proc,
						logPath,
						command,
						toolCallId,
						state,
						pi,
						uiCtx,
					)

					state.pendingDecisionJobId = job.id

					const duration = formatDuration(
						typeof params.timeout === "number"
							? params.timeout * 1_000
							: DEFAULT_TIMEOUT_MS,
					)
					pi.sendMessage(
						{
							customType: "bg-timeout",
							content:
								`⏰ Command timed out after ${duration} and has been backgrounded as ${job.id}.\n` +
								`Command: ${command}\n` +
								`PID: ${job.pid}\n` +
								`Output so far: ${job.logPath}\n\n` +
								`Use the job_decide tool with jobId "${job.id}" to decide:\n` +
								`- decision "check": inspect the output first\n` +
								`- decision "keep": let it continue running\n` +
								`- decision "kill": terminate it\n\n` +
								`Do NOT use jobs action "attach" on this job — it will block indefinitely.`,
							display: true,
							details: {
								jobId: job.id,
								logPath: job.logPath,
								command,
							},
						},
						{ deliverAs: "followUp", triggerTurn: true },
					)

					return {
						content: [
							{
								type: "text" as const,
								text: `Process backgrounded as ${job.id}\nCommand: ${command}\nPID: ${job.pid}\nOutput: ${job.logPath}`,
							},
						],
						details: undefined,
					}
				}

				clearInterval(pollTimer)
				clearTimeout(timer)
				clearTimeout(hintTimer)
				state.runningProcesses.delete(toolCallId)
				if (state.currentlyRunningToolCallId === toolCallId) {
					state.currentlyRunningToolCallId = null
				}
				state.backgroundJobs.delete(jobId)

				const output = await readFile(logPath, "utf-8").catch(() => "")

				if (
					raceResult.code !== 0 &&
					raceResult.code !== null &&
					!raceResult.interrupted
				) {
					throw new Error(
						output || `Command exited with code ${raceResult.code}`,
					)
				}

				return {
					content: [
						{
							type: "text" as const,
							text: output || "(no output)",
						},
					],
					details: undefined,
				}
			} finally {
				clearInterval(pollTimer)
				clearTimeout(timer)
				clearTimeout(hintTimer)
			}
		},
	})

	// ── bash_bg tool ────────────────────────────────────────────────────

	pi.registerTool({
		name: "bash_bg",
		label: "Background Bash",
		description:
			"Run a bash command in background immediately. Output is written to a per-session log file. " +
			"Use the jobs tool to check status and read output.",
		promptSnippet:
			"Run bash command in background without blocking conversation",
		promptGuidelines: [
			"Use bash_bg when you want to start a long-running command in background immediately.",
			"This is different from regular bash + Ctrl+B — bash_bg backgrounds from the start.",
		],
		parameters: Type.Object({
			command: Type.String({
				description: "Command to run in background",
			}),
			notify: Type.Optional(
				Type.Boolean({
					description: "Notify when complete (default: true)",
				}),
			),
		}),

		async execute(
			toolCallId,
			params,
			_signal,
			_onUpdate,
			ctx,
		): Promise<AgentToolResult<undefined>> {
			const shouldNotify = params.notify !== false
			const uiCtx: UiContext = ctx as unknown as UiContext

			if (state.tmuxAvailable) {
				const job = spawnBackgroundTmux(
					params.command,
					ctx.cwd,
					toolCallId,
					state,
					pi,
					uiCtx,
					(jobId, command, logPath) =>
						startStallWatchdog(jobId, command, logPath, pi, () => {
							killTmuxJob(
								state.backgroundJobs.get(jobId) ??
									({
										id: jobId,
										command,
										pid: -1,
										startTime: Date.now(),
										status: "running",
										logPath,
										toolCallId,
										isBackgrounded: true,
									} satisfies BackgroundJob),
							)
						}),
				)

				updateWidget(state, uiCtx)

				return {
					content: [
						{
							type: "text" as const,
							text: `Started background job ${job.id}\nCommand: ${params.command}\nOutput: ${job.logPath}`,
						},
					],
					details: undefined,
				}
			}

			const jobId = generateJobId(++state.jobCounter)
			const logPath = logPathForJob(jobId)

			const logFd = openSync(logPath, "w")
			const proc = spawn("bash", ["-c", params.command], {
				stdio: ["pipe", logFd, logFd],
				cwd: ctx.cwd,
				detached: true,
				env: { ...process.env },
			})
			closeSync(logFd)

			if (!proc.pid) {
				throw new Error("Failed to spawn background process")
			}

			const job: BackgroundJob = {
				id: jobId,
				command: params.command,
				pid: proc.pid,
				startTime: Date.now(),
				status: "running",
				logPath,
				proc,
				toolCallId,
				isBackgrounded: true,
			}
			createJobDonePromise(job)
			state.backgroundJobs.set(jobId, job)

			const cancelStall = startStallWatchdog(
				jobId,
				params.command,
				logPath,
				pi,
				() => {
					if (proc.pid) killProcessGroup(proc.pid, "SIGTERM")
					silenceJobAfterKill(job)
				},
			)

			proc.on("close", (code) => {
				cancelStall()
				markJobTerminal(
					job,
					code === 0 || code === null ? "completed" : "failed",
					code ?? 0,
				)
				clearPendingDecision(state, job)
				if (shouldNotify) notifyCompletion(job, state, pi, uiCtx)
				updateWidget(state, uiCtx)
			})

			proc.on("error", () => {
				cancelStall()
				markJobTerminal(job, "failed")
				clearPendingDecision(state, job)
				if (shouldNotify) notifyCompletion(job, state, pi, uiCtx)
				updateWidget(state, uiCtx)
			})

			updateWidget(state, uiCtx)

			return {
				content: [
					{
						type: "text" as const,
						text: `Started background job ${jobId}\nCommand: ${params.command}\nPID: ${proc.pid}\nOutput: ${logPath}`,
					},
				],
				details: undefined,
			}
		},
	})

	// ── jobs tool ───────────────────────────────────────────────────────

	pi.registerTool({
		name: "jobs",
		label: "Background Jobs",
		description:
			"List, inspect, kill, or attach to background jobs. Output is read from disk files.",
		promptSnippet: "Manage background jobs (list/output/kill/attach)",
		promptGuidelines: [
			"Use jobs with action 'list' to see all background jobs.",
			"Use jobs with action 'output' to read a job's output from its log file.",
			"Use jobs with action 'kill' to terminate a running background job.",
			"Use jobs with action 'attach' to wait for a running job and get its final output.",
		],
		parameters: Type.Object({
			action: StringEnum(["list", "output", "kill", "attach"] as const, {
				description: "Action to perform",
			}),
			jobId: Type.Optional(
				Type.String({
					description: "Job ID for output/kill/attach",
				}),
			),
			wait: Type.Optional(
				Type.Boolean({
					description:
						"For attach: wait for completion (default true)",
				}),
			),
		}),

		async execute(
			_toolCallId,
			params,
			signal,
			onUpdate,
			_ctx,
		): Promise<AgentToolResult<undefined>> {
			switch (params.action) {
				case "list": {
					const running = Array.from(state.backgroundJobs.values())
					const recent = state.recentTerminalJobs.slice(-5).reverse()
					const lines = [
						...running.map((j) => formatJobLine(j)),
						...recent.map((j) => formatJobLine(j)),
					]
					return {
						content: [
							{
								type: "text" as const,
								text:
									lines.length > 0
										? `Background Jobs:\n${lines.join("\n")}`
										: "No background jobs",
							},
						],
						details: undefined,
					}
				}

				case "output": {
					if (!params.jobId)
						throw new Error("jobId is required for action=output")
					const job = lookupJob(state, params.jobId)
					if (!job)
						throw new Error(`Job not found: ${params.jobId}`)
					const output = getTmuxContext(job)
						? await readTmuxOutput(job, MAX_OUTPUT_PREVIEW_CHARS)
						: await readOutputTail(
								job.logPath,
								MAX_OUTPUT_PREVIEW_CHARS,
						  )
					return {
						content: [
							{
								type: "text" as const,
								text: `Output for ${job.id} (${job.status})\nLog: ${job.logPath}\n\n${output}`,
							},
						],
						details: undefined,
					}
				}

				case "kill": {
					if (!params.jobId)
						throw new Error("jobId is required for action=kill")
					const job = lookupJob(state, params.jobId)
					if (!job)
						throw new Error(`Job not found: ${params.jobId}`)

					const tmuxCtx = getTmuxContext(job)
					if (tmuxCtx) {
						killTmuxJob(job)
					} else if (job.proc && job.status === "running") {
						killProcessGroup(job.proc.pid!, "SIGTERM")
					} else {
						throw new Error(`Job is not running: ${job.id}`)
					}
					silenceJobAfterKill(job)
					clearPendingDecision(state, job)
					return {
						content: [
							{
								type: "text" as const,
								text: tmuxCtx
									? `Killed tmux window ${tmuxCtx.windowId} for ${job.id}`
									: `Sent SIGTERM to ${job.id} (process group)`,
							},
						],
						details: undefined,
					}
				}

				case "attach": {
					if (!params.jobId)
						throw new Error("jobId is required for action=attach")
					const job = lookupJob(state, params.jobId)
					if (!job)
						throw new Error(`Job not found: ${params.jobId}`)

					const waitForCompletion = params.wait ?? true
					const skipWait =
						state.pendingDecisionJobId === job.id &&
						job.status === "running"

					if (
						job.status === "running" &&
						waitForCompletion &&
						!skipWait
					) {
						if (!job.donePromise) createJobDonePromise(job)

						if (job.pid > 0) {
							try {
								process.kill(job.pid, 0)
							} catch {
								markJobTerminal(job, "failed")
							}
						}

						onUpdate?.({
							content: [
								{
									type: "text" as const,
									text: `Attaching to ${job.id} (${job.status})...`,
								},
							],
							details: undefined,
						})

						if (signal && !signal.aborted) {
							const abortPromise = new Promise<void>(
								(resolve) => {
									signal.addEventListener(
										"abort",
										() => resolve(),
										{
											once: true,
										},
									)
								},
							)
							await Promise.race([job.donePromise, abortPromise])
						} else {
							await job.donePromise
						}
					}

					const output = getTmuxContext(job)
						? await readTmuxOutput(job, MAX_OUTPUT_PREVIEW_CHARS)
						: await readOutputTail(
								job.logPath,
								MAX_OUTPUT_PREVIEW_CHARS,
						  )
					job.outputConsumed = true
					return {
						content: [
							{
								type: "text" as const,
								text: `Attach finished for ${job.id}. Status: ${job.status}\nLog: ${job.logPath}\n\n${output}`,
							},
						],
						details: undefined,
					}
				}
			}
		},
	})

	// ── job_decide tool ─────────────────────────────────────────────────

	pi.registerTool({
		name: "job_decide",
		label: "Job Decision",
		description:
			"Decide what to do with a background job that timed out. Use this when prompted after a command is backgrounded.",
		promptSnippet: "Decide on a timed-out background job",
		promptGuidelines: [
			"Use job_decide with decision 'keep' to let the job continue running in the background.",
			"Use job_decide with decision 'kill' to terminate the job.",
			"Use job_decide with decision 'check' to see the job's current output before deciding.",
		],
		parameters: Type.Object({
			jobId: Type.String({
				description: "The job ID to decide on",
			}),
			decision: StringEnum(["keep", "kill", "check"] as const, {
				description:
					"keep = let it run, kill = terminate it, check = inspect output first",
			}),
		}),

		async execute(
			_toolCallId,
			params,
			_signal,
			_onUpdate,
			_ctx,
		): Promise<AgentToolResult<undefined>> {
			const job = lookupJob(state, params.jobId)
			if (!job) {
				state.pendingDecisionJobId = undefined
				return {
					content: [
						{
							type: "text",
							text: `Job ${params.jobId} not found.`,
						},
					],
					details: undefined,
				}
			}

			switch (params.decision) {
				case "kill": {
					const tmuxCtx = getTmuxContext(job)
					if (tmuxCtx) {
						killTmuxJob(job)
					} else if (job.proc && job.status === "running") {
						killProcessGroup(job.proc.pid!, "SIGTERM")
					}
					silenceJobAfterKill(job)
					state.pendingDecisionJobId = undefined
					return {
						content: [
							{ type: "text", text: `Killed ${job.id}.` },
						],
						details: undefined,
					}
				}
				case "keep": {
					state.pendingDecisionJobId = undefined
					return {
						content: [
							{
								type: "text",
								text: `Keeping ${job.id} running in the background. Use the jobs tool to check on it later.`,
							},
						],
						details: undefined,
					}
				}
				case "check": {
					const output = getTmuxContext(job)
						? await readTmuxOutput(job, MAX_OUTPUT_PREVIEW_CHARS)
						: await readOutputTail(
								job.logPath,
								MAX_OUTPUT_PREVIEW_CHARS,
						  )
					return {
						content: [
							{
								type: "text",
								text: `Output of ${job.id}:\n${output}`,
							},
						],
						details: undefined,
					}
				}
			}
		},
	})
}

// ─── Background commands (Ctrl+B/J/X, /bg /fg /jobs) ────────

async function handleBackgroundShortcut(
	state: BgState,
	pi: ExtensionAPI,
	ctx: UiContext,
): Promise<void> {
	if (state.agentBackgrounded) {
		state.agentBackgrounded = false
		ctx.ui.setStatus("agent-backgrounded", undefined)
		updateWidget(state, ctx)
		ctx.ui.notify("▶ Resumed", "info")

		pi.sendMessage(
			{
				customType: "agent-resume",
				content: "Continuing where you left off.",
				display: true,
			},
			{ deliverAs: "followUp", triggerTurn: true },
		)
		return
	}

	if (state.currentlyRunningToolCallId) {
		const rp = state.runningProcesses.get(
			state.currentlyRunningToolCallId,
		)
		if (rp) {
			rp.triggerBackground()
		}
	}

	state.agentBackgrounded = true
	ctx.ui.setStatus(
		"agent-backgrounded",
		ctx.ui.theme.fg("warning", "⏸ Backgrounded"),
	)
	updateWidget(state, ctx)

	ctx.ui.notify("⏸ Backgrounded. Ctrl+B to resume.", "info")
}

async function showTaskDetail(
	job: BackgroundJob,
	state: BgState,
	pi: ExtensionAPI,
	ctx: UiContext,
): Promise<void> {
	const duration = formatDuration(Date.now() - job.startTime)
	const statusIcon =
		job.status === "running"
			? "◐"
			: job.status === "completed"
			  ? "✅"
			  : job.status === "failed"
			    ? "❌"
			    : "🛑"

	if (job.status === "running") {
		const actions = ["Attach (wait for completion)", "Show Output", "Kill"]
		const action = await ctx.ui.select(
			`${statusIcon} ${job.id} · ${job.command.slice(0, 50)} · ${duration}`,
			actions,
		)
		if (action === undefined) return

		if (action === actions[0]) {
			ctx.ui.setStatus("bg-fg", `Attaching to ${job.id}...`)
			if (!job.donePromise) createJobDonePromise(job)
			await job.donePromise
			ctx.ui.setStatus("bg-fg", undefined)

			const output = await readOutputTail(
				job.logPath,
				MAX_OUTPUT_PREVIEW_CHARS,
			)
			const fullText =
				`${job.id} · ${job.command}\n` +
				`Status: ${job.status} · Duration: ${formatDuration(Date.now() - job.startTime)}\n` +
				`Log: ${job.logPath}\n\n--- OUTPUT ---\n${output}`

			pi.sendMessage(
				{
					customType: "bg-attach",
					content: fullText,
					display: true,
					details: { jobId: job.id, logPath: job.logPath },
				},
				{ deliverAs: "steer", triggerTurn: false },
			)
			ctx.ui.notify(`Attached ${job.id}`, "info")
		} else if (action === actions[1]) {
			const output = await readOutputTail(
				job.logPath,
				MAX_OUTPUT_PREVIEW_CHARS,
			)
			await ctx.ui.editor(
				`${statusIcon} ${job.id}: ${job.command.slice(0, 50)}`,
				`Command: ${job.command}\n` +
					`PID: ${job.pid} · Started: ${new Date(job.startTime).toLocaleString()}\n` +
					`Duration: ${duration} · Log: ${job.logPath}\n\n--- OUTPUT ---\n${output}`,
			)
		} else if (action === actions[2]) {
			const tmuxCtx = getTmuxContext(job)
			if (tmuxCtx) {
				killTmuxJob(job)
			} else if (job.proc) {
				killProcessGroup(job.proc.pid!, "SIGTERM")
			}
			silenceJobAfterKill(job)
			ctx.ui.notify(`Killed ${job.id}`, "info")
			updateWidget(state, ctx)
		}
	} else {
		const actions = ["Show Output", "Remove from List"]
		const action = await ctx.ui.select(
			`${statusIcon} ${job.id} · ${job.command.slice(0, 50)} · ${job.status}`,
			actions,
		)
		if (action === undefined) return

		if (action === actions[0]) {
			const output = await readOutputTail(
				job.logPath,
				MAX_OUTPUT_PREVIEW_CHARS,
			)
			await ctx.ui.editor(
				`${statusIcon} ${job.id}: ${job.command.slice(0, 50)}`,
				`Command: ${job.command}\n` +
					`PID: ${job.pid} · Started: ${new Date(job.startTime).toLocaleString()}\n` +
					`Status: ${job.status} · Exit code: ${job.exitCode ?? "n/a"}\n` +
					`Duration: ${duration} · Log: ${job.logPath}\n\n--- OUTPUT ---\n${output}`,
			)
		} else if (action === actions[1]) {
			state.backgroundJobs.delete(job.id)
			ctx.ui.notify(`Removed ${job.id}`, "info")
			updateWidget(state, ctx)
		}
	}
}

async function showTasksInterface(
	state: BgState,
	pi: ExtensionAPI,
	ctx: UiContext,
): Promise<void> {
	const allJobs = Array.from(state.backgroundJobs.values())
	const runningJobs = allJobs.filter((j) => j.status === "running")
	const finishedJobs = allJobs.filter((j) => j.status !== "running")

	const items: string[] = []
	if (state.agentBackgrounded) {
		items.push("◐ agent · backgrounded · Ctrl+B to resume")
	}
	for (const job of runningJobs) {
		const duration = formatDuration(Date.now() - job.startTime)
		items.push(`◐ ${job.id}: ${job.command.slice(0, 40)} · ${duration}`)
	}
	for (const job of finishedJobs) {
		const statusIcon =
			job.status === "completed"
				? "✅"
				: job.status === "failed"
				  ? "❌"
				  : "🛑"
		items.push(`${statusIcon} ${job.id}: ${job.command.slice(0, 40)}`)
	}

	if (items.length === 0) {
		ctx.ui.notify("No background tasks", "info")
		return
	}

	const choice = await ctx.ui.select("Background Tasks", items)
	if (choice === undefined) return

	if (state.agentBackgrounded && choice === items[0]) {
		await handleBackgroundShortcut(state, pi, ctx)
		return
	}

	const selectedJob = [...runningJobs, ...finishedJobs].find((j) =>
		choice?.includes(j.id),
	)
	if (selectedJob) {
		await showTaskDetail(selectedJob, state, pi, ctx)
	}
}

function registerBackgroundCommands(
	pi: ExtensionAPI,
	state: BgState,
): void {
	pi.registerShortcut("ctrl+b", {
		description: "Background bash/agent, or resume backgrounded agent",
		handler: async (ctx) => {
			await handleBackgroundShortcut(
				state,
				pi,
				ctx as unknown as UiContext,
			)
		},
	})

	pi.registerShortcut("ctrl+j", {
		description: "Open background tasks",
		handler: async (ctx) => {
			await showTasksInterface(state, pi, ctx as unknown as UiContext)
		},
	})

	pi.registerShortcut("shift+down", {
		description: "Open background tasks",
		handler: async (ctx) => {
			await showTasksInterface(state, pi, ctx as unknown as UiContext)
		},
	})

	pi.registerShortcut("ctrl+x", {
		description: "Kill most recent running background task",
		handler: async (ctx) => {
			const uiCtx = ctx as unknown as UiContext
			const runningJobs = Array.from(state.backgroundJobs.values())
				.filter((j) => j.status === "running")
				.sort((a, b) => b.startTime - a.startTime)

			if (runningJobs.length === 0) {
				uiCtx.ui.notify("No running tasks to kill", "warning")
				return
			}

			const job = runningJobs[0]
			const tmuxCtx = getTmuxContext(job)
			if (tmuxCtx) {
				killTmuxJob(job)
			} else if (job.proc) {
				killProcessGroup(job.proc.pid!, "SIGTERM")
			}
			silenceJobAfterKill(job)
			uiCtx.ui.notify(`Killed ${job.id}`, "info")
			updateWidget(state, uiCtx)
		},
	})

	pi.registerCommand("bg", {
		description: "Background bash/agent, or resume backgrounded agent",
		handler: async (_args, ctx: ExtensionCommandContext) => {
			await handleBackgroundShortcut(
				state,
				pi,
				ctx as unknown as UiContext,
			)
		},
	})

	pi.registerCommand("fg", {
		description:
			"Attach to a background job (/fg [job-id] [--snapshot]); defaults to most recent running job",
		handler: async (args, ctx: ExtensionCommandContext) => {
			const uiCtx = ctx as unknown as UiContext
			const parts = args.trim().split(/\s+/).filter(Boolean)
			const snapshot =
				parts.includes("--snapshot") || parts.includes("-s")
			const explicitJobId = parts.find((p) => !p.startsWith("-"))

			let job: BackgroundJob | undefined
			if (explicitJobId) {
				job = state.backgroundJobs.get(explicitJobId)
				if (!job) {
					uiCtx.ui.notify(`Job not found: ${explicitJobId}`, "error")
					return
				}
			} else {
				job = Array.from(state.backgroundJobs.values())
					.filter((j) => j.status === "running")
					.sort((a, b) => b.startTime - a.startTime)[0]

				if (!job) {
					uiCtx.ui.notify(
						"No running background jobs to attach. Usage: /fg [job-id] [--snapshot]",
						"warning",
					)
					return
				}
			}

			uiCtx.ui.setStatus(
				"bg-fg",
				`Attaching to ${job.id}${snapshot ? " (snapshot mode)" : ""}...`,
			)
			try {
				if (!snapshot && job.status === "running") {
					if (!job.donePromise) createJobDonePromise(job)
					await job.donePromise
				}

				const output = await readOutputTail(
					job.logPath,
					MAX_OUTPUT_PREVIEW_CHARS,
				)
				const fullText =
					`Job: ${job.id}\nCommand: ${job.command}\nStatus: ${job.status}\n` +
					`PID: ${job.pid}\nStarted: ${new Date(job.startTime).toLocaleString()}\n` +
					`Log: ${job.logPath}\n\n--- OUTPUT ---\n${output}`

				pi.sendMessage(
					{
						customType: "bg-attach",
						content: fullText,
						display: true,
						details: {
							jobId: job.id,
							logPath: job.logPath,
						},
					},
					{ deliverAs: "steer", triggerTurn: false },
				)
				uiCtx.ui.notify(
					`Attached output posted for ${job.id}`,
					"info",
				)
			} finally {
				uiCtx.ui.setStatus("bg-fg", undefined)
			}
		},
	})

	pi.registerCommand("jobs", {
		description: "Show and manage background tasks",
		handler: async (_args, ctx: ExtensionCommandContext) => {
			await showTasksInterface(state, pi, ctx as unknown as UiContext)
		},
	})
}

// ─── Terminal notifications (original power-tools) ──────────

function sendTerminalNotification(title: string, body: string) {
	const term = process.env.TERM_PROGRAM ?? ""

	// OSC 777 — Ghostty, iTerm2, WezTerm, rxvt-unicode
	if (
		term === "ghostty" ||
		term === "iTerm.app" ||
		term === "WezTerm" ||
		term === "rxvt-unicode"
	) {
		process.stdout.write(`\x1b]777;notify;${title};${body}\x07`)
		return
	}

	// OSC 99 — Kitty
	if (process.env.KITTY_WINDOW_ID) {
		process.stdout.write(`\x1b]99;i=1:d=0;${title}\x1b\\`)
		process.stdout.write(`\x1b]99;i=1:p=body;${body}\x1b\\`)
		return
	}
}

function truncateNotificationBody(text: string): string {
	const firstLine = text.split("\n")[0] ?? ""
	if (firstLine.length <= NOTIFICATION_BODY_MAX) return firstLine
	return firstLine.slice(0, NOTIFICATION_BODY_MAX - 1) + "…"
}

// ─── Main Extension ─────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	// ── Background state ──
	const state: BgState = {
		backgroundJobs: new Map(),
		runningProcesses: new Map(),
		jobCounter: 0,
		currentlyRunningToolCallId: null,
		agentBackgrounded: false,
		pendingDecisionJobId: undefined,
		tmuxAvailable: isTmuxAvailable(),
		nonInteractive: detectNonInteractive(
			process.argv,
			process.stdin?.isTTY ?? false,
		),
		completedJobCount: 0,
		failedJobCount: 0,
		recentTerminalJobs: [],
	}

	registerBackgroundJobs(pi, state)
	registerBackgroundCommands(pi, state)

	// ── Notifications state ──
	let notifyEnabled = true
	let lastAgentMsg = ""

	// ── Git checkpoints state ──
	const checkpoints = new Map<string, string>()
	let currentEntryId: string | undefined

	// ── Lifecycle: pill bar timer ──
	let pillTimer: ReturnType<typeof setInterval> | null = null

	pi.on("session_start", async (_event, ctx) => {
		cleanupStaleTmuxRunDirs()
		cleanupStaleLogs()
		if (!pillTimer) {
			pillTimer = setInterval(
				() => updateWidget(state, ctx as unknown as UiContext),
				PILL_INTERVAL,
			)
		}
	})

	pi.on("session_shutdown", async () => {
		if (pillTimer) {
			clearInterval(pillTimer)
			pillTimer = null
		}
	})

	// ── AGENT TRACKING + NOTIFICATIONS ──
	pi.on("agent_end", async (_event, ctx) => {
		if (notifyEnabled) {
			const body = lastAgentMsg
				? truncateNotificationBody(lastAgentMsg)
				: "Ready for input"
			sendTerminalNotification("Pi", body)
		}
	})

	pi.on("message_end", async (event) => {
		if (event.message.role === "assistant") {
			const texts =
				event.message.content
					?.filter((c: any) => c.type === "text")
					.map((c: any) => c.text)
					.join("\n") ?? ""
			if (texts) lastAgentMsg = texts
		}
	})

	pi.registerCommand("notifications", {
		description: "Configure terminal notifications (on/off/status)",
		handler: async (args, ctx) => {
			const arg = args.trim().toLowerCase()
			if (!arg || arg === "status") {
				ctx.ui.notify(
					`Notifications: ${notifyEnabled ? "on" : "off"}`,
					"info",
				)
			} else if (arg === "on" || arg === "enable" || arg === "1") {
				notifyEnabled = true
				ctx.ui.notify("Notifications enabled", "info")
			} else if (arg === "off" || arg === "disable" || arg === "0") {
				notifyEnabled = false
				ctx.ui.notify("Notifications disabled", "info")
			} else {
				ctx.ui.notify("Usage: /notifications [on|off|status]", "info")
			}
		},
	})

	// ── GIT CHECKPOINTS ──
	pi.on("tool_result", async (_event, ctx) => {
		const leaf = ctx.sessionManager.getLeafEntry()
		if (leaf) currentEntryId = leaf.id
	})

	pi.on("turn_start", async () => {
		try {
			const { stdout } = await pi.exec("git", ["stash", "create"])
			const ref = stdout.trim()
			if (ref && currentEntryId) {
				checkpoints.set(currentEntryId, ref)
			}
		} catch {
			// Not a git repo — silent
		}
	})

	pi.on("session_before_fork", async (event, ctx) => {
		const ref = checkpoints.get(event.entryId)
		if (!ref || !ctx.hasUI) return

		const choice = await ctx.ui.select("Restore code state?", [
			"Yes, restore code to checkpoint",
			"No, keep current code",
		])

		if (choice?.startsWith("Yes")) {
			try {
				await pi.exec("git", ["stash", "apply", ref])
				ctx.ui.notify("Code restored to checkpoint", "info")
			} catch {
				ctx.ui.notify("Failed to restore checkpoint", "error")
			}
		}
	})

	pi.on("agent_end", async () => {
		checkpoints.clear()
	})
}
