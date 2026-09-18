# Central nixpkgs package configuration for hosts that import this tree.
#
# Overlay order is the list order below. fish-compat and packages override
# disjoint attributes (fish postInstall vs kitty/v2raya), so the order only
# matters for readability.
{pkgs, ...}: {
  nixpkgs.config = {
    permittedInsecurePackages = [
      "pnpm-10.29.2"
      "electron-39.8.10"
    ];
  };

  nixpkgs.overlays = [
    (import ../overlays/fish-compat.nix)
    (import ../overlays/packages.nix)
  ];
}
