{
  config,
  lib,
  pkgs,
  ...
}: let
  adminEmail = "ezzibrahimx@gmail.com";
  db = "sqlite+/var/lib/goatcounter/db.sqlite3";
in {
  config = lib.mkIf config.my.server.goatcounter.enable {
    # GoatCounter — cookieless, self-hosted web analytics for the Aldebaran
    # site (aldebaran.moe + sciadv.almiraj.xyz). Fronted by Caddy at
    # analytics.almiraj.xyz (see public.nix). SQLite storage.

    users.users.goatcounter = {
      isSystemUser = true;
      group = "goatcounter";
      home = "/var/lib/goatcounter";
      createHome = true;
    };
    users.groups.goatcounter = {};

    systemd.services.goatcounter = {
      description = "GoatCounter web analytics";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        User = "goatcounter";
        Group = "goatcounter";
        Restart = "on-failure";
        RestartSec = "5s";
        ExecStart = "${pkgs.goatcounter}/bin/goatcounter serve -listen 127.0.0.1:8050 -db ${db} -automigrate";
      };
    };

    # First-run only: create the analytics.almiraj.xyz site + admin user.
    # Password is generated once and stored under the service dir (root-only);
    # re-runs are no-ops once the site exists. Retries in case serve is still
    # running the initial DB migration.
    systemd.services.goatcounter-init = {
      description = "Create GoatCounter site";
      after = ["goatcounter.service"];
      requires = ["goatcounter.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -e
        GC=${pkgs.goatcounter}/bin/goatcounter
        pwfile=/var/lib/goatcounter/admin-password
        email=${adminEmail}
        if $GC db show site -find analytics.almiraj.xyz -db ${db} >/dev/null 2>&1; then
          exit 0
        fi
        # Ensure the schema exists up front so we don't run the create while
        # serve is still applying automigrations (idempotent, safe to repeat).
        $GC db migrate all -createdb -db ${db} >/dev/null 2>&1 || true
        # Reuse a stored password if present, else generate once and persist it.
        if [ -f "$pwfile" ]; then
          pw="$(cat "$pwfile")"
        else
          pw="$(${pkgs.openssl}/bin/openssl rand -hex 20)"
          umask 077
          echo "$pw" > "$pwfile"
          chown goatcounter:goatcounter "$pwfile"
        fi
        for i in $(seq 1 30); do
          if $GC db create site -db ${db} \
            -vhost analytics.almiraj.xyz \
            -user.email "$email" \
            -user.password "$pw" \
            >/dev/null 2>&1; then
            echo "goatcounter-init: site analytics.almiraj.xyz created"
            exit 0
          fi
          sleep 2
        done
        echo "goatcounter-init: could not create site" >&2
        exit 1
      '';
    };
  };
}