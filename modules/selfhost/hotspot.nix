{
  config,
  pkgs,
  lib,
  ...
}: {
  # ── Hotspot (SSID "nir") ──────────────────────────────────────────
  boot.extraModprobeConfig = ''
    options iwlwifi bt_coex_active=0 disable_11ax=1
  '';

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
