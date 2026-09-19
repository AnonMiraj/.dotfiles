# Vaultwarden: Bitwarden-compatible password server.
#
# Loopback only. Caddy fronts it with the shared wildcard certificate, so it is
# reachable on the home LAN and over the tailnet (headscale pushes the split DNS
# for `*.${my.lan.domain}`) and never from the public internet.
#
# Secrets live in secrets/secrets.yaml as `vaultwarden-env`: ADMIN_TOKEN, the
# SMTP block, and optionally PUSH_INSTALLATION_KEY. systemd reads that file
# after the store-generated env file, so its values win over the ones below.
#
# IMPORTANT: do not change settings in the web admin panel. Anything saved there
# lands in /var/lib/vaultwarden/config.json, which takes precedence over BOTH
# this module and the sops env file. It has already shadowed SIGNUPS_ALLOWED
# (left true) and IP_HEADER (left X-Real-IP, which clients can forge) once.
# Recover with:
#   sudo rm /var/lib/vaultwarden/config.json && sudo systemctl restart vaultwarden
# The admin panel is for Users and Diagnostics only.
{
  config,
  lib,
  pkgs,
  ...
}: let
  domain = config.my.lan.domain;
  vps = "admin@${config.my.vps.address}";

  backupDir = "/mnt/media/backups/vaultwarden";
  snapshotDir = "/mnt/media/backups/vaultwarden-snapshots";
  keepDays = 14;

  # Same pinned host key and key file as modules/backup.nix.
  sshOpts = [
    "-o"
    "BatchMode=yes"
    "-o"
    "StrictHostKeyChecking=accept-new"
    "-o"
    "UserKnownHostsFile=/etc/ssh/ssh_known_hosts"
    "-o"
    "GlobalKnownHostsFile=/dev/null"
    "-i"
    "/home/nir/.ssh/id_ed25519"
  ];

  # The module's backup job keeps exactly one copy in backupDir, on the same
  # physical disk as the live database. This rotates dated snapshots and mirrors
  # them to the VPS, so a corrupt or deleted database cannot take out every copy.
  snapshot = pkgs.writeShellScriptBin "vaultwarden-snapshot" ''
    set -euo pipefail

    src="${backupDir}"
    snap="${snapshotDir}"

    if [ ! -d "$src" ]; then
      echo "backup dir $src missing" >&2
      exit 1
    fi

    mkdir -p "$snap"
    stamp=$(${pkgs.coreutils}/bin/date +%Y-%m-%d)
    tmp="$snap/.vaultwarden-$stamp.tar.gz.part"

    ${pkgs.gnutar}/bin/tar -czf "$tmp" -C "$(${pkgs.coreutils}/bin/dirname "$src")" "$(${pkgs.coreutils}/bin/basename "$src")"
    ${pkgs.coreutils}/bin/mv -f "$tmp" "$snap/vaultwarden-$stamp.tar.gz"

    ${pkgs.findutils}/bin/find "$snap" -maxdepth 1 -type f -name 'vaultwarden-*.tar.gz' -mtime +${toString keepDays} -delete

    ${pkgs.rsync}/bin/rsync -az --delete --timeout=300 \
      --rsync-path='sudo rsync' \
      -e "ssh ${lib.concatStringsSep " " sshOpts}" \
      "$snap/" "${vps}:/var/backups/vaultwarden/"
  '';
in {
  # Editing the secret alone does not restart the service, because the module
  # sets EnvironmentFile without a restart trigger. Without this, a sops edit
  # (SMTP, ADMIN_TOKEN) silently keeps running with the old values.
  sops.secrets."vaultwarden-env".restartUnits = ["vaultwarden.service"];

  services.vaultwarden = {
    enable = true;
    backupDir = backupDir;
    environmentFile = config.sops.secrets."vaultwarden-env".path;
    config = {
      DOMAIN = "https://vault.${domain}";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "critical";
      # Bootstrap: temporarily allow signups, register, then close again.
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = true;
      SHOW_PASSWORD_HINT = false;
      # Caddy sets X-Forwarded-For to the real client address and replaces any
      # value the client sent, so logs and rate limits cannot be spoofed.
      IP_HEADER = "X-Forwarded-For";
      LOG_LEVEL = "warn";
      # Mobile push notifications: flip to true, set PUSH_INSTALLATION_ID here,
      # and put PUSH_INSTALLATION_KEY in the sops env file. Both come free from
      # https://bitwarden.com/host. F-Droid builds cannot receive push.
      PUSH_ENABLED = false;
    };
  };

  # /mnt/media is a `nofail` mount: without this, tmpfiles would create the
  # backup directory on the root filesystem and the daily job would happily
  # fill it, while the real media disk sits unmounted.
  systemd.services.backup-vaultwarden = {
    unitConfig.RequiresMountsFor = "/mnt/media";
    unitConfig.ConditionPathIsMountPoint = "/mnt/media";
  };

  systemd.services.vaultwarden-snapshot = {
    description = "Rotate vaultwarden backups into dated snapshots and copy them to almiraj";
    requires = ["network-online.target"];
    after = ["backup-vaultwarden.service" "network-online.target"];
    unitConfig = {
      RequiresMountsFor = "/mnt/media";
      ConditionPathIsMountPoint = "/mnt/media";
    };
    path = [pkgs.rsync pkgs.openssh];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${snapshot}/bin/vaultwarden-snapshot";
    };
  };

  systemd.timers.vaultwarden-snapshot = {
    description = "Daily vaultwarden off-box snapshot";
    wantedBy = ["timers.target"];
    timerConfig = {
      # Half an hour after backup-vaultwarden (23:00 default).
      OnCalendar = "23:30";
      Persistent = true; # catch up after the desktop has been off
    };
  };
}
