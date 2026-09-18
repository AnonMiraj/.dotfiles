{pkgs, ...}: {
  programs.kdeconnect.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-vkcapture
      obs-pipewire-audio-capture
      obs-wayland-hotkeys
      obs-source-record
      obs-gstreamer
      obs-vaapi
      obs-composite-blur
    ];
  };

  programs.fish = {
    enable = true;
    # Generates a completion file for every package in systemPackages that
    # ships man pages. Upstream nixpkgs now extracts fish's embedded
    # generator script itself, so this no longer needs the fish override that
    # used to live in overlays/fish-compat.nix.
    generateCompletions = true;
  };

  programs.bash = {
    interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
      	shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
      	exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  # nvf manages neovim — see users/nir/nvf/.
  programs.neovim.enable = true;
}
