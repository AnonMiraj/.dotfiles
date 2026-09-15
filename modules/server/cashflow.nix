{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cashflow = import ../../pkgs/cashflow {
    inherit (pkgs) lib buildNpmPackage nodejs_22;
    cashflowSrc = inputs.cashflow;
  };
in {
  config = lib.mkIf config.my.server.cashflow.enable {
    # GOOGLE_CLIENT_ID only (own file so the value can be rotated alone).
    sops.secrets.cashflow-env = {
      path = "/run/secrets/cashflow-env";
      restartUnits = ["cashflow.service"];
    };

    users.groups.cashflow = {};
    users.users.cashflow = {
      isSystemUser = true;
      group = "cashflow";
      home = "/var/lib/cashflow";
      description = "Cash Flow game server";
    };

    systemd.services.cashflow = {
      description = "Cash Flow game server";
      after = ["network-online.target" "sops-nix.service"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      environment = {
        PORT = "3100";
        HOST = "127.0.0.1";
        DATA_DIR = "/var/lib/cashflow/data";
        OWNER_KEY_FILE = "/var/lib/cashflow/.owner-key";
      };
      serviceConfig = {
        User = "cashflow";
        Group = "cashflow";
        StateDirectory = "cashflow";
        StateDirectoryMode = "0700";
        EnvironmentFile = config.sops.secrets.cashflow-env.path;
        ExecStart = "${pkgs.nodejs_22}/bin/node ${cashflow}/lib/cashflow/server/index.js";
        Restart = "on-failure";
        RestartSec = "5s";
        UMask = "0077";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = ["/var/lib/cashflow"];
      };
    };

    # public.nix turns this entry into the Caddy vhost (see its `stackOf` map).
    my.publicServices.cashflow = {
      domain = "cashflow.almiraj.xyz";
      port = 3100;
      checkPath = "/api/health";
      group = "games";
      openFirewall = false; # binds 127.0.0.1; Caddy fronts it
    };
  };
}
