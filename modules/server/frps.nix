{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.server.frps.enable {
    # frp server — terminates frp tunnels from home `niro` (kept: home services
    # are exposed publicly through it). Listen on 7000 (current frps.toml).
    #
    # Config → sops frps-toml (backup value: bindPort = 7000). If an auth token
    # is added, it must match the home frpc in modules/selfhost.
    sops.secrets.frps-toml = {path = "/run/secrets/frps.toml";};

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