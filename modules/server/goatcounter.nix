{
  config,
  lib,
  pkgs,
  ...
}: {
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
  };
}