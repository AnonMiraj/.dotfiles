{ config, lib, pkgs, ... }:

let
  cfg = config.my.batterySuspend;

  # Returns "1" if any Mains power supply is online, "0" otherwise
  hasACOnline = pkgs.writeShellScript "has-ac-online" ''
    for f in /sys/class/power_supply/*/type; do
      type=$(cat "$f" 2>/dev/null)
      [ "$type" = "Mains" ] || continue
      online=$(cat "$(dirname "$f")/online" 2>/dev/null)
      [ "$online" = "1" ] && { echo "1"; exit 0; }
    done
    echo "0"
  '';

  suspendScript = pkgs.writeShellScript "battery-suspend" ''
    set -euo pipefail

    # Only one instance at a time
    exec 9>/tmp/battery-suspend.lock
    ${pkgs.util-linux}/bin/flock -n 9 || exit 0

    # AC back (e.g. flicker during grace period)? done.
    [ "$(${hasACOnline})" = "1" ] && exit 0

    # Grace period — might come back soon
    sleep ${toString cfg.gracePeriod}

    [ "$(${hasACOnline})" = "1" ] && exit 0

    # Check RTC wakealarm available
    if [ ! -f /sys/class/rtc/rtc0/wakealarm ]; then
      echo "battery-suspend: no RTC wakealarm, falling back to plain suspend" \
        | ${pkgs.systemd}/bin/systemd-cat -t battery-suspend
      exec ${pkgs.systemd}/bin/systemctl suspend
    fi

    echo "battery-suspend: AC lost, suspending ${cfg.suspendMode} for ${toString cfg.checkInterval}s" \
      | ${pkgs.systemd}/bin/systemd-cat -t battery-suspend

    exec ${pkgs.util-linux}/bin/rtcwake -m ${cfg.suspendMode} -s ${toString cfg.checkInterval}
  '';

  resumeScript = pkgs.writeShellScript "battery-resume" ''
    set -euo pipefail

    if [ "$(${hasACOnline})" = "1" ]; then
      echo "battery-suspend: AC restored, staying awake" \
        | ${pkgs.systemd}/bin/systemd-cat -t battery-suspend
      exit 0
    fi

    echo "battery-suspend: still on battery, re-suspending" \
      | ${pkgs.systemd}/bin/systemd-cat -t battery-suspend

    if [ ! -f /sys/class/rtc/rtc0/wakealarm ]; then
      exec ${pkgs.systemd}/bin/systemctl suspend
    fi

    exec ${pkgs.util-linux}/bin/rtcwake -m ${cfg.suspendMode} -s ${toString cfg.checkInterval}
  '';
in {
  options.my.batterySuspend = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable automatic suspend on battery with periodic RTC wake to check if AC restored.
        Harmless on desktops — does nothing when AC is online.
      '';
    };

    gracePeriod = lib.mkOption {
      type = lib.types.int;
      default = 600;
      description = "Seconds to wait after AC loss before first suspend. Lets short outages pass.";
    };

    checkInterval = lib.mkOption {
      type = lib.types.int;
      default = 3600;
      description = "Seconds between RTC wake-ups to re-check AC status.";
    };

    suspendMode = lib.mkOption {
      type = lib.types.enum [ "mem" "disk" "freeze" ];
      default = "mem";
      description = ''
        Suspend mode:
        - mem   = suspend to RAM (fast, small battery drain)
        - disk  = hibernate (slower resume, zero battery drain)
        - freeze = suspend to idle (lightweight, may not wake from RTC)
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.battery-suspend = {
      description =
        "Battery power-loss handler — wait grace period then suspend with periodic RTC wake";
      after = [ "local-fs.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${suspendScript}";
      };
    };

    # Trigger when AC unplugged
    services.udev.extraRules = ''
      SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl --no-block start battery-suspend"
    '';

    # Check on every resume/wake
    powerManagement.resumeCommands = ''
      ${resumeScript}
    '';
  };
}
