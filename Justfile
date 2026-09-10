check:
	nix flake check

fmt:
	nix fmt

update:
	nix flake update

write-flake:
	nix run .#write-flake

# VPS (almiraj) — second host in this flake (aarch64)
vps-host := "ssh.almiraj.xyz"
vps-admin := "admin"

# Build + deploy the almiraj config ON the VPS (arm64 builder).
# Requires the box to already run NixOS + ssh key for admin@vps-host.
deploy-almiraj:
	@test -n "$(command -v nixos-rebuild)" || { echo 'need nixos-rebuild'; exit 1; }
	nixos-rebuild switch --flake .#almiraj \
		--build-host {{vps-admin}}@{{vps-host}} \
		--target-host {{vps-admin}}@{{vps-host}}

build-almiraj:
	nix build .#nixosConfigurations.almiraj.config.system.build.toplevel --no-link
