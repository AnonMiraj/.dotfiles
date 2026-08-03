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

  # Native NetworkManager hotspot (SSID "nir"). Replaces the old create_ap +
  # dispatcher setup, which died on outages: ethernet-down stopped the AP, NM
  # grabbed wlan as a client, and create_ap's virtual-AP creation then hit
  # "Device or resource busy" -> infinite systemd restart loop (100+ restarts).
  # NM keeps the AP up through ethernet outages; NAT resumes when the uplink returns.
  systemd.services.nm-hotspot = {
    description = "NetworkManager hotspot profile (nir)";
    wantedBy = ["multi-user.target"];
    wants = ["NetworkManager.service"];
    after = ["NetworkManager.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      EnvironmentFile = "/var/lib/secrets/hotspot.env";
    };
    script = ''
      PROFILE=nir-hotspot
      # Let NM release the wifi phy, then remove leftover create_ap virtual
      # interfaces (ap*). NM's own AP activation holds the phy, which would
      # make ip link del fail with EBUSY, so the radio must be off while
      # deleting. Restart radio and re-create the profile afterwards.
      # Set regulatory domain (unlocks full 5 GHz channels)
      ${pkgs.iw}/bin/iw reg set EG 2>/dev/null || true
      ${pkgs.networkmanager}/bin/nmcli radio wifi off || true
      i=0
      while [ $i -lt 15 ]; do
        leftover=$(ls /sys/class/net | grep '^ap' || true)
        [ -z "$leftover" ] && break
        for iface in $leftover; do
          ${pkgs.iw}/bin/iw dev "$iface" del 2>/dev/null || ${pkgs.iproute2}/bin/ip link del dev "$iface" 2>/dev/null || true
        done
        i=$((i + 1))
        sleep 2
      done
      rm -rf /tmp/create_ap*
      if ${pkgs.networkmanager}/bin/nmcli -t connection show "$PROFILE" >/dev/null 2>&1; then
        ${pkgs.networkmanager}/bin/nmcli connection delete "$PROFILE"
      fi
      ${pkgs.networkmanager}/bin/nmcli radio wifi on || true
      sleep 3
      ${pkgs.networkmanager}/bin/nmcli connection add \
        type wifi ifname wlp0s20f3 con-name "$PROFILE" \
        ssid nir \
        wifi.mode ap \
        wifi-sec.key-mgmt wpa-psk \
        wifi-sec.psk "$HOTSPOT_PASSWORD" \
        wifi-sec.proto rsn \
        wifi-sec.pairwise ccmp \
        wifi-sec.group ccmp \
        wifi-sec.pmf disable \
        802-11-wireless.cloned-mac-address permanent \
        ipv4.method shared ipv6.method shared \
        802-11-wireless.band bg \
        802-11-wireless.channel 6 \
        autoconnect yes
      ${pkgs.networkmanager}/bin/nmcli connection up "$PROFILE" || true
    '';
  };

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
