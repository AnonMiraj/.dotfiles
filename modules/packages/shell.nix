# Shell, prompt, and CLI conveniences.
#
# Cross-host essentials (ripgrep, fd, fzf, eza, bat, jq, direnv, ...) live in
# modules/shared.nix instead, so they are present on the VPS too.
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    fish
    kitty
    starship
    zoxide
    glow
    fastfetch
    killall
    gdu
    ripdrag
    pnpm
    just
  ];
}
