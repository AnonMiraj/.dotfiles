check:
	nix flake check

fmt:
	nix fmt

update:
	nix flake update

write-flake:
	nix run .#write-flake
