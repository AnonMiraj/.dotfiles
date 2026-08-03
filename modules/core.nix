{
  config,
  pkgs,
  lib,
  ...
}: {
  security.sudo.extraRules = [
    {
      users = ["nir"];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = ["NOPASSWD" "SETENV"];
        }
        {
          command = "/nix/var/nix/profiles/default/bin/nix";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
  networking.hostName = "niro"; # Define your hostname.
  # networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.macAddress = "random";


  # Set your time zone.
  time.timeZone = "Africa/Cairo";
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024;
    }
  ];
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nir = {
    isNormalUser = true;
    description = "nir";
    extraGroups = ["networkmanager" "wheel" "adbusers" "docker" "i2c"];
    shell = pkgs.fish;
    packages = with pkgs; [
    ];
  };
  programs.nix-ld.enable = true;
  # Enable Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.daemon.settings.features.cdi = true;
  hardware.nvidia-container-toolkit.enable = true;
  hardware.i2c.enable = true;
  hardware.enableRedistributableFirmware = true;

  # Samsung download mode (heimdall) — systemd uaccess grants to local console users
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", ATTR{idProduct}=="685d", MODE="0666", TAG+="uaccess"
  '';

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [22 5000 8000 9999];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    substituters = ["https://cache.nixos-cuda.org" "https://vicinae.cachix.org"];
    trusted-public-keys = ["cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="];
    trusted-users = ["root" "nir"];
    # subminer source build needs sandbox disabled for bun install (network)
    sandbox = false;
  };

  # ── AppImage support ────────────────────────────────────────
  programs.appimage.enable = true;
}
