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
          command = "/run/current-system/sw/bin/nix";
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
    extraGroups = ["networkmanager" "wheel" "docker" "i2c" "input" "audio"];
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
    trusted-users = ["root" "nir"];
  };

  # ── AppImage support ────────────────────────────────────────
  programs.appimage.enable = true;
}
