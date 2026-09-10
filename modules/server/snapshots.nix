{
  config,
  lib,
  pkgs,
  ...
}: let
  snapScript = pkgs.writeShellScript "btrfs-snapshots" ''
    set -euo pipefail
    BTRFS="${pkgs.btrfs-progs}/bin/btrfs"
    TS=$(date +%Y%m%d-%H%M)
    DEST=/var/btrfs-snapshots
    mkdir -p "$DEST"
    N=14 # keep this many
    # docker data subvol (@docker mounted at /var/lib/docker)
    $BTRFS subvolume snapshot -r /var/lib/docker "$DEST/docker-$TS"
    # prune oldest
    ls -d "$DEST"/docker-* 2>/dev/null \
      | sort | head -n -$N \
      | xargs -r -n1 $BTRFS subvolume delete -c
  '';
in {
  config = lib.mkIf config.my.server.public {
    systemd.services.btrfs-snapshots = {
      description = "Nightly btrfs snapshot of docker data";
      requires = ["var-lib-docker.mount"];
      after = ["var-lib-docker.mount"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = snapScript;
      };
    };
    systemd.timers.btrfs-snapshots = {
      description = "Run btrfs-snapshots nightly";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "*-*-* 04:00:00";
        Persistent = true;
        RandomizedDelaySec = "15m";
      };
    };
  };
}