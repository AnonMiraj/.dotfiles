{config, lib, pkgs, ...}: let
  vps = "admin@152.53.81.54";
  dest = "/mnt/media/backups/almiraj";
  sshOpts = [
    "-o"
    "BatchMode=yes"
    "-o"
    "StrictHostKeyChecking=accept-new"
    "-i"
    "/home/nir/.ssh/id_ed25519"
  ];

  script = pkgs.writeShellScriptBin "almiraj-vps-backup" ''
    set -euo pipefail

    # (dest src) pairs — trailing source slash copies contents not the dir
    targets="nixos:/etc/nixos 3x-ui:/var/lib/3x-ui caddy:/var/lib/caddy gatus:/var/lib/gatus"

    for t in $targets; do
      name="''${t%%:*}"
      src="''${t#*:}"
      mkdir -p "${dest}/$name"
      echo "== backing up $name ($src)"
      rsync \
        -az --delete --timeout=300 \
        --rsync-path='sudo rsync' \
        -e "ssh ${builtins.concatStringsSep " " sshOpts}" \
        "${vps}:$src/" "${dest}/$name/"
    done
  '';
in {
  # Off-box backup: pull critical almiraj VPS data to niro /mnt/media.
  # This module is imported by the niro host only (VPS imports just
  # base.nix + modules/server/*), so it runs on the desktop pulling FROM the box.

  systemd.services.almiraj-vps-backup = {
    description = "Off-box rsync backup of almiraj VPS to /mnt/media";
    requires = ["network-online.target"];
    after = ["network-online.target"];
    unitConfig.RequiresMountsFor = "/mnt/media";
    path = [pkgs.rsync pkgs.openssh];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${script}/bin/almiraj-vps-backup";
    };
  };

  systemd.timers.almiraj-vps-backup = {
    description = "Daily almiraj VPS backup";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true; # catch up after downtime (desktop sleeps/off)
    };
  };
}
