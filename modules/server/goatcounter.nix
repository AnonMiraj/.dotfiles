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
      script = pkgs.writeShellScript "goatcounter-init" ''
        set -e
        GC=${pkgs.goatcounter}/bin/goatcounter
        pwfile=/var/lib/goatcounter/admin-password
        if $GC db show site -find analytics.almiraj.xyz -db ${db} >/dev/null 2>&1; then
          exit 0
        fi
        attempt=0
        while ! $GC db create site -createdb -db ${db} \
          -vhost analytics.almiraj.xyz \
          -user.email ${adminEmail} \
          -user.password "$(${pkgs.openssl}/bin/openssl rand -hex 20)" \
          -format table >/dev/null 2>&1; do
          attempt=$((attempt + 1))
          [ "$attempt" -ge 30 ] && { echo "goatcounter-init: could not create site" >&2; exit 1; }
          sleep 2
        done
        pw=$(${pkgs.openssl}/bin/openssl rand -hex 20)
        $GC db update site -find analytics.almiraj.xyz -db ${db} \
          -user.email ${adminEmail} -user.password "$pw" -format table >/dev/null 2>&1 || true
        umask 077
        echo "$pw" > "$pwfile"
        chown goatcounter:goatcounter "$pwfile"
        echo "goatcounter-init: site analytics.almiraj.xyz created"
      '';
    };
  };
}