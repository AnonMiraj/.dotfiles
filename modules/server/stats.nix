{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption types;
  cfg = config.my.server.stats;
  docroot = "/var/www/stats";
  geoipDir = "/var/lib/geoip";
  # DB-IP Lite (CC BY 4.0, no account needed) publishes monthly City + ASN
  # databases. This month's file may not exist yet at the start of a month, so
  # fall back to the previous one.
  geoipFetch = pkgs.writeShellScript "dbip-fetch" ''
    set -eu
    mkdir -p ${geoipDir}
    for kind in city asn; do
      ok=0
      for offset in 0 1; do
        ym=$(${pkgs.coreutils}/bin/date -u -d "-$offset month" +%Y-%m)
        url="https://download.db-ip.com/free/dbip-$kind-lite-$ym.mmdb.gz"
        if ${pkgs.curl}/bin/curl -fsSL -o ${geoipDir}/tmp.gz "$url"; then
          ${pkgs.gzip}/bin/gzip -dc ${geoipDir}/tmp.gz > ${geoipDir}/dbip-$kind-lite.mmdb.new
          mv ${geoipDir}/dbip-$kind-lite.mmdb.new ${geoipDir}/dbip-$kind-lite.mmdb
          echo "geoip: $kind-lite updated from $ym"
          ok=1
          break
        fi
      done
      [ "$ok" = 1 ] || echo "geoip: $kind-lite download failed (keeping existing file)" >&2
    done
    rm -f ${geoipDir}/tmp.gz
  '';

  # GoAccess' per-path panels (Requested Files, 404s, MIME, ...) have no host
  # column, so with several subdomains in one report you cannot tell where a
  # path came from. Prefix the logged URI with its Host so rows read
  # `gsoc.almiraj.xyz/organization/x/`. Key order is preserved, which the
  # CADDY JSON log-format relies on.
  annotateHost = pkgs.writeText "stats-annotate-host.py" ''
    import json, sys

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        request = entry.get("request") or {}
        host, uri = request.get("host"), request.get("uri")
        if host and uri:
            request["uri"] = host + uri
        sys.stdout.write(json.dumps(entry) + "\n")
  '';
in {
  # stats.almiraj.xyz — GoAccess HTML reports built from the per-vhost JSON
  # access logs the NixOS Caddy module already writes to ${logDir} (see
  # services.caddy.virtualHosts.<host>.logFormat). Nothing is injected into
  # any page: this covers mirrored sites, crawlers and API traffic too.
  config = mkIf cfg.enable {
    services.caddy.virtualHosts."stats.almiraj.xyz" = {
      extraConfig = ''
        # Login page + session cookie are served by tinyauth
        # (modules/server/tinyauth.nix); unauthenticated requests get a 302
        # to auth.almiraj.xyz instead of a browser basic-auth dialog.
        forward_auth 127.0.0.1:${toString config.my.server.tinyauth.port} {
          uri /api/auth/caddy
        }
        root * ${docroot}
        file_server
      '';
    };

    systemd.tmpfiles.rules = [
      "d ${docroot} 0755 root root -"
    ];

    systemd.services.goaccess-stats = {
      description = "Render GoAccess reports from Caddy access logs";
      after = lib.optional cfg.geoip "dbip-geoip-update.service";
      wants = lib.optional cfg.geoip "dbip-geoip-update.service";
      serviceConfig = {
        Type = "oneshot";
        Nice = 10;
      };
      script = ''
        shopt -s nullglob
        files=(/var/log/caddy/access-*.log*)
        ((''${#files[@]})) || { echo "no access logs yet"; exit 0; }
        mkdir -p ${docroot}

        geo=()
        if [ -f ${geoipDir}/dbip-city-lite.mmdb ]; then
          geo+=(--geoip-database ${geoipDir}/dbip-city-lite.mmdb)
        fi
        if [ -f ${geoipDir}/dbip-asn-lite.mmdb ]; then
          geo+=(--geoip-database ${geoipDir}/dbip-asn-lite.mmdb)
        fi

        # zcat -f handles both plain and rotated .gz logs. Drop the monitoring
        # and ACME noise so the numbers reflect real visitors, then tag each
        # path with its host (see annotateHost above).
        ${pkgs.gzip}/bin/zcat -f "''${files[@]}" \
          | ${pkgs.gnugrep}/bin/grep -v -E '"User-Agent":\["Gatus|acme-challenge' \
          | ${pkgs.python3}/bin/python3 ${annotateHost} \
          | ${pkgs.goaccess}/bin/goaccess \
              --log-format=CADDY \
              ${lib.optionalString cfg.anonymizeIp "--anonymize-ip"} \
              ''${geo[@]+"''${geo[@]}"} \
              --no-progress \
              --html-report-title "almiraj access stats (GeoIP: DB-IP Lite)" \
              --output ${docroot}/.index.tmp.html \
              -
        # Atomic swap so a browser never reads a half-written report.
        mv -f ${docroot}/.index.tmp.html ${docroot}/index.html
      '';
    };

    systemd.timers.goaccess-stats = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "*:0/10";
        Persistent = true;
        RandomizedDelaySec = "30";
      };
    };

    systemd.services.dbip-geoip-update = mkIf cfg.geoip {
      description = "Download/refresh DB-IP Lite GeoIP databases";
      serviceConfig = {
        Type = "oneshot";
        Nice = 15;
        ExecStart = "${geoipFetch}";
      };
    };

    systemd.timers.dbip-geoip-update = mkIf cfg.geoip {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "monthly";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };

  # Declared here (not in options.nix) because they're specific to this stack.
  options.my.server.stats = {
    anonymizeIp = mkOption {
      type = types.bool;
      default = true;
      description = "Zero the last IPv4 octet / last 80 IPv6 bits in the reports.";
    };
    geoip = mkOption {
      type = types.bool;
      default = true;
      description = "Annotate reports with country/city/ASN via DB-IP Lite (refreshed monthly).";
    };
  };
}
