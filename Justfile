check:
	nix flake check --no-build
	nixos-rebuild build --flake .#niro

fmt:
	nix fmt

update:
	nix flake update

write-flake:
	nix run .#write-flake

# Preview the lab DNS diff. dnscontrol reads the generated config and the
# sops-rendered Cloudflare creds; root is needed for the creds file.
dns-preview:
	sudo dnscontrol preview --config /etc/dnscontrol/dnsconfig.js --creds /run/secrets/rendered/cloudflare-dns-creds.json

# VPS (almiraj) — second host in this flake (aarch64)
vps-host := "ssh.almiraj.xyz"
vps-admin := "admin"

# Build + deploy the almiraj config ON the VPS (arm64 builder).
# Requires the box to already run NixOS + ssh key for admin@vps-host.
deploy-almiraj:
	@test -n "$(command -v nixos-rebuild)" || { echo 'need nixos-rebuild'; exit 1; }
	nixos-rebuild switch --flake .#almiraj \
		--build-host {{vps-admin}}@{{vps-host}} \
		--target-host {{vps-admin}}@{{vps-host}} \
		--elevate=sudo

# Plan the aarch64 closure (evaluate + dry build). The x86_64 desktop
# cannot build aarch64 and we do not want the closure copied back; the
# real build happens in deploy-almiraj on the VPS.
build-almiraj:
	nixos-rebuild dry-build --flake .#almiraj
