{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.server.frps.enable {
    sops.secrets.frps-toml = {
      path = "/run/secrets/frps.toml";
      restartUnits = ["frps"]; # reload config (incl. auth token) on rotate
    };

    systemd.services.frps = {
      description = "frp server (tunnel terminus for home)";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.frp}/bin/frps -c /run/secrets/frps.toml";
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
      };
    };

    networking.firewall.allowedTCPPorts = [7000];

    # runtime data
    users.users.frps = {
      isSystemUser = true;
      group = "frps";
    };
    users.groups.frps = {};
  };
}