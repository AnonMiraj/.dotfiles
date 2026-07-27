{pkgs, ...}: {
  imports = [
    ./settings.nix
    ./keymap.nix
    ./plugins.nix
  ];

  # Extra packages needed by yazi plugins (fzf, etc.)
  home.packages = with pkgs; [
    glow
    ouch
    ripdrag
    xxhash
    fzf
    ripgrep
    bat
  ];

  # Session: sync yanked files across sessions (built-in)
  programs.yazi.initLua = ''
    require("session"):setup({ sync_yanked = true })
    require("zoxide"):setup {
      update_db = true,
    }
  '';

  programs.yazi = {
    enable = true;
    package = pkgs.yazi;
    shellWrapperName = "y";
    # Theme — noctalia flavor (provided by programs.noctalia)
    theme = {
      flavor = {
        dark = "noctalia";
        light = "noctalia";
      };
    };
  };

  xdg.configFile."yazi/theme.toml".force = true;
}
