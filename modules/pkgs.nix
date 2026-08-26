{
  config,
  pkgs,
  inputs,
  ...
}: {
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "pnpm-10.29.2"
      "electron-39.8.10"
    ];
  };

  nixpkgs.overlays = [
    (final: prev: {
      fish = prev.fish.overrideAttrs (old: { doCheck = false; });
      kitty = prev.kitty.overrideAttrs (old: {
        doCheck = false;
        doInstallCheck = false;
      });
      v2raya = prev.v2raya.overrideAttrs (old: {
        tags = [ "with_gvisor" ];
      });
    })
  ];



  # ── Shell & CLI tools ──────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Shell
    fish
    kitty
    starship
    zoxide
    fzf
    fd
    eza
    bat
    ripgrep
    jq
    glow
    fastfetch
    btop
    killall
    gdu
    ripdrag
    pnpm
    just
    direnv

    # Dev tools
    git
    git-lfs
    lazygit
    diff-so-fancy
    gh
    opencode
    tuicr
    claude-code
    code-cursor-fhs
    neovim
    python3
    cargo
    rustc
    nodejs
    bun
    uv
    gnumake
    ccache
    clang
    gcc
    zig
    lld
    lldb
    rust-analyzer
    nil
    tinymist
    lua-language-server
    clang-tools

    # Formatters / Linters
    shfmt
    alejandra
    stylua
    golines
    black
    rustfmt
    prettier

    # SubMiner / Japanese media tools
    ffmpegthumbnailer
    python3Packages.guessit
    mecab
    anki
    (import ../pkgs/subminer { inherit inputs pkgs; })
    # Media
    (mpv.override {
      scripts = with mpvScripts; [
        autoload
        autosub
        autosubsync-mpv
        memo
        mpris
        thumbfast
        uosc
      ];
    })
    ffmpeg
    obs-studio
    yazi
    ouch
    unar
    unrar
    zip
    xz
    unzip
    p7zip
    mediainfo
    yt-dlp
    ffsubsync
    (import ../pkgs/alass { inherit (pkgs) lib stdenv fetchurl autoPatchelfHook; })
    cava
    newsboat
    nsxiv
    readest
		epub-thumbnailer
		calibre
    imagemagick
    ghostscript
    zathura
    xournalpp
    typst
    pandoc

    # Audio
    pulsemixer
    mpd
    mpc
    ncmpcpp
    mpd-mpris

    # Graphics / GPU
    vulkan-tools
    mesa-demos
    xrandr
    xwayland-satellite
    xdotool
    xwininfo

    # Network / Comms
    wget
    websocat
    socat
    scrcpy
    telegram-desktop
    vesktop
    brave
    transmission_4-gtk
    protonup-rs
    sshfs
    mkcert
    i2c-tools
    ddcutil
    heimdall
    android-tools
    adb-sync
    (import ../pkgs/odin4 { inherit (pkgs) lib stdenv fetchurl unzip autoPatchelfHook libusb1; })
    (import ../pkgs/hiddify { inherit (pkgs) lib appimageTools fetchurl; })

    # System
    cachix
    sops
    ssh-to-age
    inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.stasis.packages.${pkgs.stdenv.hostPlatform.system}.stasis
    vicinae
    tremc
    inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli
    trash-cli
    presenterm
    wl-clipboard
    wtype
    hyprwhspr-rs
    whisper-cpp
    libnotify
    xxhash
    xdg-desktop-portal-termfilechooser
    zenity

    # Cursors
    bibata-cursors-translucent
    bibata-cursors

    # Lua
    luarocks
    lua5_1
    luajitPackages.magick

    # Gaming
    lutris
    umu-launcher
    steam
  ];

  programs.kdeconnect.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # ── Shell ──────────────────────────────────────────────────────
  programs.fish = {
    enable = true;
    generateCompletions = false; # fish 4.8.0 removed create_manpage_completions.py
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

  # ── Fonts ──────────────────────────────────────────────────────
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
    # Disable subpixel rendering (rgba=none) — ported from old dotfiles
    hinting = {
      enable = true;
      autohint = false;
    };
    subpixel = {
      rgba = "none";
      lcdfilter = "none";
    };
  };

  # ── Editors ────────────────────────────────────────────────────
  # nvf manages neovim — see users/nir/nvf.nix
  programs.neovim.enable = true;
}
