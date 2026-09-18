# Central nixpkgs package configuration for hosts that import this tree.
{...}: {
  nixpkgs.overlays = [
    (import ../overlays/packages.nix)
  ];
}
