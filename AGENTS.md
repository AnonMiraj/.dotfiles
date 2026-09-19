# AGENTS.md

## Project Overview

NixOS configuration for host `niro`, managed with `flake-parts`, `flake-file`, and `flake-aspects`. The flake is generated from `nix/flake-file.nix`. Modules under `modules/` and `nix/` are auto-imported via `import-tree`. Formatting via `treefmt-nix`.

## Conventions

- **Module Management**: Use `import-tree`. Avoid hardcoding module paths.
- **Flake Inputs**: Define `flake-file.inputs` in `nix/flake-file.nix`.
- **Flake Generation**: Do NOT edit `flake.nix` manually. Run `nix run .#write-flake`.
- **Commit Style**: Conventional commits (`feat:`, `fix:`, `chore:`, `docs:`).

## Available Skills

- **`/skill:flake-aspects`**: Defining/modifying flake aspects and transposition.
- **`/skill:flake-file`**: Managing flake inputs and regenerating `flake.nix`.
- **`/skill:import-tree`**: Directory-tree imports in the `nix/` module tree.
- **`/skill:caveman`**: Terse communication mode (used by default).

## Structure

- **`flake.nix`**: Generated. Do not edit directly.
- **`nix/flake-file.nix`**: Source flake definition and input declarations.
- **`nix/hosts.nix`**: Shared host config builders (`self.lib.configs.*`).
- **`nix/hosts/niro/`**: Host definition for `niro` using `flake.aspects`.
- **`nix/`**: Main module tree auto-imported by `import-tree`.
- **`modules/`**: NixOS modules imported by the host config. Everything here
  except `shared.nix`, `public-services.nix`, and `server/` is desktop-only,
  because `niro` imports the whole tree while `almiraj` imports
  `modules/shared.nix`, `modules/public-services.nix`, plus `modules/server/`.
  - `shared.nix` — genuinely cross-host base (locale, nix settings, docker, ssh)
  - `public-services.nix` — shared public service registry + Homepage VPS list
  - `system.nix` — niro host identity, users, networking, hardware, base services
  - `boot.nix` — grub + EFI (niro)
  - `nvidia.nix` — GPU, kernel parameters and PRIME offload (niro)
  - `desktop.nix` — display server, pipewire, portals, compositors
  - `fonts.nix` — fonts and fontconfig
  - `programs.nix` — `programs.*` blocks (fish, steam, obs-studio, ...)
  - `overlays.nix` — `nixpkgs.overlays` and `permittedInsecurePackages`
  - `packages/` — desktop package lists, one file per concern
  - `backup.nix`, `battery-suspend.nix` — host services
  - `selfhost/` — all exposed services:
    - `options.nix` — `my.*` options (`my.services`, `my.lan`, `my.vps`, `my.caddy`, `my.pushStatus`)
    - `metadata.nix` — service data (add a service = add one block)
    - `caddy.nix` — Caddy vhosts
    - `homepage.nix` — Homepage dashboard entries
    - `gatus.nix` — local Gatus web config + generated endpoints
    - `push-status.nix` — pushes local health to the VPS Gatus
    - `acme.nix` — Let's Encrypt wildcard cert via Cloudflare DNS-01
    - `config.nix` — Avahi, dnsmasq, `/etc/hosts` split-brain entries
    - `headscale-client.nix` — Tailscale client + 192.168.1.0/24 subnet router
    - `containers.nix` — docker containers
    - `hotspot.nix` — NetworkManager hotspot profile
    - `services.nix` — NixOS service enablement
  - `server/` — VPS-only modules (`my.server.*`), see the VPS notes below
- **`lib/selfhost.nix`**: Shared derivations used by `modules/selfhost/*`
  (`domainOf`, `displayName`, `acmeHost`, ...). Not a module, so `import-tree`
  ignores it; import it explicitly with `import ../../lib/selfhost.nix`.
- **`users/nir/`**: Home-manager configuration (import-tree auto-imports).
  - `pi/default.nix` — pi agent settings, packages, extensions, skills, keybindings
- **`secrets/secrets.yaml`**: Encrypted secrets (sops + SSH key).
- **`.pi/skills/`**: Project-specific agent skills.

## Adding a Service

1. Add metadata block to `modules/selfhost/metadata.nix`:
   ```nix
   myservice = { port = 1234; domain = "sub"; homepage.group = "Media"; };
   ```
2. Optionally add NixOS config in `modules/selfhost/services.nix`.
3. Caddy vhost, Homepage entry, and Gatus check are auto-generated.
   The Let's Encrypt wildcard cert covers `*.<my.lan.domain>` automatically.
## Development Workflow

1. Edit module in `nix/`, `modules/`, or `users/nir/`.
2. Add flake inputs in `nix/flake-file.nix` if required.
3. Run `nix run .#write-flake` to regenerate `flake.nix`.
4. Run `nix fmt` before committing.
5. `nix flake check` to verify.
6. `sudo nixos-rebuild switch` to apply.

## Key Fixes Made

- **sops Secrets**: `.sops.yaml` uses native age key (`age1...`) not `ssh-ed25519` format.
  When re-encrypting, use `sops --encrypt --config .sops.yaml <file>` with the file
  under `secrets/` so creation rules match.
- **Push-status**: Add `gatus.enable = false` to skip services without push tokens.
- **Pi Extensions**: npm pi packages (telegram, memory, tasks, etc.) listed in `packages` array
  in `users/nir/pi/default.nix` under `home.file.".pi/agent/settings.json"`.
  pi auto-installs them via npm on startup.
- **Brave API key** (pi-web-access): stored in `secrets/secrets.yaml` as `brave-api-key`.
  sops writes it to `~/.pi/web-search.json` (symlink to `/run/secrets/brave-api-key`).
- **Split-brain DNS / ACME**: `my.lan.domain` (`lab.almiraj.xyz`) is served on the
  LAN by dnsmasq and publicly only for the DNS-01 TXT challenge. Caddy uses the
  wildcard cert from `modules/selfhost/acme.nix`. The Cloudflare token lives in
  `secrets/secrets.yaml` as `cloudflare-dns-api-token` (Zone:DNS:Edit on
  `almiraj.xyz`). Replace the placeholder before rebuilding.

## VPS Status Page (status.niro.almiraj.xyz)

Gatus on the VPS (`almiraj`) receives pushed status from all home services with
`gatus.enable = true`. The push runs via `push-status.service`
(triggered by `push-status.timer`).

**Sync mechanism**:
- Home `push-status` checks each service's port, then POSTs to VPS Gatus external API
- VPS gatus config is **declarative** (`modules/server/gatus.nix`) — `external-endpoints`
  match pushes by key (`group_Name`), tokens are inline there
- Keys must match between home push and VPS module: `core_Homepage`, `media_Jellyfin`, etc.

**When adding/removing a service**:
1. Update `modules/selfhost/metadata.nix` (add/remove block)
2. `sudo nixos-rebuild switch` on the desktop
3. Update the matching `external-endpoints` in `modules/server/gatus.nix`
4. Redeploy the VPS (deploy recipe in README.md); push-status then starts/stops automatically

**Tokens** (home side): in `secrets/secrets.yaml` under `gatus-push-tokens`.
Edit with `SOPS_AGE_KEY_FILE=$HOME/.age/key.txt sops secrets/secrets.yaml`.
Must match the values in `modules/server/gatus.nix` on the VPS.

## Headscale (tailnet)

- Control server: `https://headscale.almiraj.xyz` (VPS, `modules/server/headscale.nix`).
- Home node: `niro` (`modules/selfhost/headscale-client.nix`) advertises `192.168.1.0/24`.
- Preauth key: `secrets/secrets.yaml` as `headscale-auth-key`. It has a limited
  lifetime (24h in the example); the registered node itself does not expire.
  Rotate by generating a new key and updating sops before it is needed again.
- Headscale pushes split DNS `lab.almiraj.xyz -> 192.168.1.6`.
- FRP and the VPS `home` SSH hop were removed; tailnet access replaces them.
- Cloudflare DNS-only A records for every `*.lab.almiraj.xyz` name point to
  `192.168.1.6`, so phone browsers that use public/DoH DNS still reach Niro on
  the home LAN. Without Tailscale off-LAN those names resolve to a private IP
- Cloudflare DNS-only A records for every `*.lab.almiraj.xyz` name point to
  `192.168.1.6`, so phone browsers that use public/DoH DNS still reach Niro on
  the home LAN. Without Tailscale off-LAN those names resolve to a private IP
  and time out, which is intended.
- ACL policy: `modules/server/headscale.nix` writes
  `/etc/headscale/policy.hujson` (grants: own devices plus
  `192.168.1.0/24` on 22/53/80/443/ICMP). Reload with
  `sudo systemctl reload headscale`; the unit restarts when the file changes.
- Embedded DERP is enabled on the VPS (region 999, STUN UDP 3478); TLS is
  terminated by Caddy on 443.
- VPS CLI: `sudo headscale users list`, `nodes list`, `nodes list-routes`,
  `nodes approve-routes -i 1 -r 192.168.1.0/24`.
- New key: `sudo headscale preauthkeys create --user 1 --reusable --expiration 24h`.
- Android: Tailscale -> alternate server `https://headscale.almiraj.xyz`, then
  use an auth key or web login + `headscale auth register --auth-id <id> --user anonmiraj`.


## VPS (almiraj) two-host notes

- Access: `ssh admin@152.53.81.54` (passwordless sudo; desktop key `~/.ssh/id_ed25519`).
  `root` is locked.
- VPS services live in `modules/server/` (`my.server.<x>.enable`), enable in
  `nix/hosts/almiraj/default.nix`. `niro` excludes that dir at import.
- Secrets for the VPS are in `secrets/vps.yaml` (sops, age = box host key + desktop key).
- Deploy recipe + what's running: see README.md and `../Documents/servernetcup/todo.txt`.
- Off-box backup: `modules/backup.nix` on `niro` pulls VPS data
  (`/etc/nixos`, 3x-ui, caddy, gatus) to `/mnt/media/backups/almiraj` daily.

