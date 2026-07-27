{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  home.username = "nir";
  home.homeDirectory = "/home/nir";
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
  };

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
      };
    };
  };

  # Regenerate age key from SSH: ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.age/key.txt
  home.sessionVariables = {
    GTK_USE_PORTAL = "1";
    GDK_DEBUG = "portals";
    SOPS_AGE_KEY_FILE = "$HOME/.age/key.txt";
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "kitty";
    LANG = "en_US.UTF-8";
  };

  xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = let
    wrapper =
      pkgs.runCommand "yazi-wrapper.sh"
      {
        nativeBuildInputs = [pkgs.makeWrapper];
        script = "${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh";
      } ''
        makeWrapper $script $out/wrapper \
          --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.kitty pkgs.yazi pkgs.coreutils pkgs.gnused pkgs.bash]} \
          --set TERMCMD "${pkgs.kitty}/bin/kitty --class=file_chooser"
      '';
  in ''
    [filechooser]
    cmd=${wrapper}/wrapper
    default_dir=$HOME
    open_mode = suggested
    save_mode = last
  '';

  imports = [
    inputs.zen-browser.homeModules.beta
    inputs.noctalia.homeModules.default
    inputs.nvf.homeManagerModules.default
    (inputs.import-tree.filterNot (path: lib.hasSuffix "home.nix" path) ./.)
    ./niri
  ];

  # Jellyfin MPV Shim
  services.jellyfin-mpv-shim = {
    enable = true;
    settings = {
      auto_play = true;
    };
  };
}
