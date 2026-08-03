{
  config,
  pkgs,
  lib,
  ...
}: {
  # ── Hotspot (SSID "nir") ──────────────────────────────────────────
  # NetworkManager native AP mode. Replaces the old create_ap + dispatcher
  # setup, which died on outages (ethernet-down stopped the AP, NM grabbed
  # wlan as a client, create_ap VIF add hit EBUSY → restart loop).
  # NM keeps the AP up through ethernet outages; NAT resumes when the
  # uplink returns.
  #
  # Intel AX211 5 GHz AP mode is broken at the firmware level (iwlwifi
  # LAR blocks initate-radiation on U-NII-1; U-NII-3 phone can't scan).
  # Stuck on 2.4 GHz ch 6, WPA2-only, PMF disabled for max compatibility.

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

  # Boost NM's hotspot dnsmasq (default cache 150 → 1000 entries)
  environment.etc."NetworkManager/dnsmasq-shared.d/cache.conf".text = ''
    cache-size=1000
    neg-ttl=60
  '';
}
