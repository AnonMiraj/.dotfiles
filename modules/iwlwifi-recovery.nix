# Recovery watchdog for the Intel AX1650i (CNVi, iwlwifi).
#
# Firmware so-a0-hr-b0-89.ucode asserts on the 5 GHz roam path
# ("Microcode SW error", "Too many device errors", endless
# "Scan failed! ret -5"). The device stays dead until the module is
# reloaded; a warm reboot often boots straight into the wedged state.
# Reloading iwlwifi restores it in seconds. Matching profile is pinned
# to 2.4 GHz in its NetworkManager profile (802-11-wireless.band bg).
{
  pkgs,
  lib,
  ...
}: let
  recovery = pkgs.writeShellApplication {
    name = "iwlwifi-recovery";
    runtimeInputs = with pkgs; [
      networkmanager
      kmod
      systemd
      gnugrep
      gnused
      gawk
      coreutils
    ];
    text = ''
      # Radio intentionally off: nothing to recover.
      if nmcli -t -f WIFI radio | grep -qx 'disabled'; then
        exit 0
      fi

      dev=$(nmcli -t -f DEVICE,TYPE device status |
        awk -F: '$2 == "wifi" && $1 !~ /^p2p/ { print $1; exit }')
      if [ -z "$dev" ]; then
        exit 0
      fi

      # Only act when the interface is not connected: a working link must
      # never be torn down by this timer. `-g` prints just the value,
      # "100 (connected)" when healthy — beware substring matches:
      # "30 (disconnected)" also contains "connected".
      state=$(nmcli -g GENERAL.STATE device show "$dev")
      if [ "$state" = "100 (connected)" ]; then
        exit 0
      fi

      # Look for a firmware wedge in the kernel log. The window is wide
      # because a wedged device can go silent while still failing scans.
      if ! journalctl -k --since "-10min" --no-pager 2>/dev/null |
        grep -qE 'iwlwifi.*(Microcode SW error|Scan failed! ret -5|Too many device errors)'; then
        exit 0
      fi

      echo "iwlwifi firmware wedge detected on $dev, reloading module"
      nmcli radio wifi off || true
      sleep 1
      modprobe -r iwlmvm || true
      modprobe -r iwlwifi || true
      sleep 2
      modprobe iwlwifi || true
      sleep 3
      nmcli radio wifi on || true
      sleep 2
      nmcli connection up Sigma || true
      echo "iwlwifi reloaded"
    '';
  };
in {
  systemd.services.iwlwifi-recovery = {
    description = "Reload iwlwifi when the AX1650i firmware wedges";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe recovery;
    };
  };

  systemd.timers.iwlwifi-recovery = {
    description = "Check for a wedged iwlwifi firmware";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "3min";
      OnUnitActiveSec = "2min";
      # Never fire while the interface is still coming up.
      RandomizedDelaySec = "15s";
    };
  };
}
