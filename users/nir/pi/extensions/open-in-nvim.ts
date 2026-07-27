import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"
import { writeFileSync, readFileSync, unlinkSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { execSync } from "node:child_process"

export default function (pi: ExtensionAPI) {
	pi.registerShortcut("alt+e", {
		description: "Open current prompt in Neovim",
		handler: async (ctx) => {
			const currentText = ctx.ui.getEditorText()
			const tmpFile = join(tmpdir(), `pi-prompt-${Date.now()}.md`)
			writeFileSync(tmpFile, currentText, "utf-8")

			try {
				execSync(`nvim "${tmpFile}"`, { stdio: "inherit" })
				const newText = readFileSync(tmpFile, "utf-8")
				if (newText !== currentText) {
					ctx.ui.setEditorText(newText)
				}
			} finally {
				try { unlinkSync(tmpFile) } catch {}
			}
		},
	})
}
