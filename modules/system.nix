# Niro system-level configuration: host identity, users, networking, hardware
# and base services. This module is desktop-only — `nix/hosts/niro/default.nix`
# imports the whole modules/ tree, while almiraj imports only modules/shared.nix
# and modules/server/.
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
  # Intel AX1650i (iwlwifi, so-a0-hr-b0-89.ucode): firmware asserts when it
  # joins the 5 GHz BSSID of SSID Sigma and dies until the driver is
  # reloaded. The Sigma profile is therefore pinned to 2.4 GHz, and
  # modules/iwlwifi-recovery.nix reloads the driver when it wedges anyway.
  networking.networkmanager.wifi.macAddress = "preserve";
  networking.networkmanager.wifi.scanRandMacAddress = false;
  networking.networkmanager.wifi.powersave = false;

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
  hardware.bluetooth.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [22 5000 8000 9999];

  nix.settings = {
    trusted-users = ["root" "nir"];
  };

  # Journal was volatile, so iwlwifi crash history died on reboot.
  services.journald.settings.Journal.Storage = "persistent";
}
