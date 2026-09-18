{pkgs, ...}: {
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    amiri
    source-sans-pro
    cascadia-code
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts.monospace = ["FiraCode Nerd Font"];
    # Disable subpixel rendering (rgba=none) — ported from old dotfiles.
    hinting = {
      enable = true;
      autohint = false;
    };
    subpixel = {
      rgba = "none";
      lcdfilter = "none";
    };
  };
}
