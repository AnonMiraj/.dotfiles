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


  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  # Kill worst process before RAM thrash freezes box.
  services.earlyoom.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nir = {
    isNormalUser = true;
    description = "nir";
    extraGroups = ["networkmanager" "wheel" "adbusers" "docker" "i2c" "input" "audio"];
    shell = pkgs.fish;
    packages = with pkgs; [
    ];
  };
  programs.nix-ld.enable = true;
  virtualisation.docker.daemon.settings.features.cdi = true;
  hardware.nvidia-container-toolkit.enable = true;
  hardware.i2c.enable = true;
  hardware.enableRedistributableFirmware = true;

  # Samsung download mode (heimdall) — systemd uaccess grants to local console users
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", ATTR{idProduct}=="685d", MODE="0666", TAG+="uaccess"
  '';


  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [22 5000 8000 9999];

  nix.settings = {
    substituters = ["https://cache.nixos-cuda.org" "https://vicinae.cachix.org"];
    trusted-public-keys = ["cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="];
    trusted-users = ["root" "nir"];
    # subminer source build needs sandbox disabled for bun install (network)
    sandbox = false;
  };

  # ── AppImage support ────────────────────────────────────────
  programs.appimage.enable = true;
}
