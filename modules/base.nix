{ config, lib, pkgs, ... }: {
  # Shared NixOS base — imported by every host (desktop `niro` + VPS `almiraj`).
  # Keep only genuinely cross-host settings here; host-specific things live in
  # each host's default.nix or per-host modules (e.g. modules/server/*).
  time.timeZone = "Africa/Cairo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Common nix settings. Per-host substituters / trusted-users / sandbox live in
  # each host's own `nix.settings` block (they merge in).
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
  };

  # Docker engine — desktop and VPS both run containers.
  virtualisation.docker.enable = true;

  # OpenSSH server on every host. Keys-only / account policy is per-host.
  services.openssh.enable = true;

  # ── GLOBAL packages — useful on every host (desktop niro + VPS almiraj) ──
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    curl
    wget
    jq
    git
    git-lfs
    ripgrep
    fd
    fzf
    eza
    bat
    htop
    btop
    tmux
    tree
    unzip
    zip
    xz
    openssl
    socat
    netcat-openbsd
    dnsutils
    traceroute
    mtr
    rsync
    fastfetch
    neovim
    python3
    age
    sops
    ssh-to-age
    direnv
    tldr
    strace
    sysstat
  ];
}
