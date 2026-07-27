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
- **`modules/`**: NixOS modules imported by the host config.
  - `core.nix` — base system (network, users, docker, ssh, nix)
  - `desktop.nix` — display server, pipewire, portals
  - `pkgs.nix` — system packages (grouped)
  - `selfhost/` — all exposed services:
    - `options.nix` — `my.services` option (port, domain, homepage, gatus, frp)
    - `metadata.nix` — service data (add a service = add one block)
    - `generators.nix` — auto-generates Caddy vhosts, Homepage, FRP, Gatus, push-status
    - `services.nix` — NixOS service enablement
    - `config.nix` — Avahi + Dnsmasq
    - `gatus.nix` — local Gatus web config
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
3. Caddy vhost, Homepage entry, FRP proxy, and Gatus check are auto-generated.

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
## VPS Status Page (status.niro.almiraj.xyz)

Gatus on the VPS receives pushed status from all local services with `gatus.enable = true`.
The push runs via `push-status.service` (triggered by `push-status.timer`).

**Sync mechanism**:
- Local `push-status` checks each service's port, then POSTs to VPS Gatus external API
- VPS Gatus has `external-endpoints` in `/root/gatus/config.yaml` that match by key (`group_Name`)
- Keys must match between local push and VPS config: `core_Homepage`, `media_Jellyfin`, etc.

**When adding/removing a service**:
1. Update `modules/selfhost/metadata.nix` (add/remove block)
2. Run `sudo nixos-rebuild switch`
3. **Manually update VPS config**:
   ```bash
   ssh root@almiraj.xyz
   nano /root/gatus/config.yaml  # add/remove external-endpoints matching the keys
   ```
4. Push-status starts/stops sending automatically

**Tokens**: stored in `secrets/secrets.yaml` under `gatus-push-tokens`.
Edit with `SOPS_AGE_KEY_FILE=$HOME/.age/key.txt sops secrets/secrets.yaml`.
Token must match between local secrets and VPS config.

**Current VPS endpoints**: all `my.services` with `gatus.enable = true`.

