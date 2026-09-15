{
  config,
  lib,
  pkgs,
  ...
}: let
  # GoatCounter ships a Countries GeoIP DB, so the Locations panel works out of
  # the box. When the shared DB-IP Lite City database exists (see
  # modules/server/stats.nix) this installs it where GoatCounter auto-detects it
  # (first *.mmdb in ./goatcounter-data), adding city/region detail. It runs on
  # every service start, so a freshly downloaded DB applies after a restart.
  geoipInstall = pkgs.writeShellScript "goatcounter-geoip-install" ''
    if [ -f /var/lib/geoip/dbip-city-lite.mmdb ]; then
      ${pkgs.coreutils}/bin/install -Dm644 \
        /var/lib/geoip/dbip-city-lite.mmdb \
        /var/lib/goatcounter/goatcounter-data/dbip-city-lite.mmdb
    fi
  '';
in {
  config = lib.mkIf config.my.server.goatcounter.enable {
    services.goatcounter = {
      enable = true;
      package = pkgs.goatcounter;
      address = "127.0.0.1";
      port = 8050;
      proxy = true;
      extraArgs = [
        "-db"
        "sqlite+/var/lib/goatcounter/db.sqlite3"
        "-automigrate"
      ];
    };

    systemd.services.goatcounter.serviceConfig.ExecStartPre =
      lib.mkIf config.my.server.stats.geoip
      ["+${geoipInstall}"];
  };
}
