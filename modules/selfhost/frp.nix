# FRP client: expose selected home services through the VPS frps.
{
  config,
  lib,
  pkgs,
  ...
}: let
  h = import ../../lib/selfhost.nix {inherit lib config;};
  inherit (lib) filterAttrs mapAttrsToList;
  inherit (h) remotePortOf;
in {
  sops.secrets.frpc-token = {
    path = "/run/secrets/frpc-token";
    restartUnits = ["frp-frpc.service"]; # re-auth frp tunnel when the token rotates
  };

  services.frp.instances.frpc = {
    enable = true;
    role = "client";
    settings = {
      serverAddr = config.my.vps.address;
      serverPort = 7000;
      loginFailExit = false;
      log.level = "info";
      auth.token = "\${FRPC_TOKEN}";
      proxies = mapAttrsToList (name: svc: {
        inherit name;
        type = "tcp";
        localIP = "127.0.0.1";
        localPort = svc.port;
        remotePort = remotePortOf svc;
      }) (filterAttrs (_: svc: svc.frp.enable) config.my.services);
    };
    environmentFiles = [config.sops.secrets.frpc-token.path];
  };

  # frp does not expand \${ENV} in TOML configs, so bake the real token into a
  # runtime copy in preStart (token comes from the sops EnvironmentFile).
  systemd.services.frp-frpc = let
    frpcBaseToml =
      (pkgs.formats.toml {}).generate "frp-frpc-base.toml"
      config.services.frp.instances.frpc.settings;
  in {
    serviceConfig = {
      RuntimeDirectory = "frp-frpc";
      ExecStart =
        lib.mkForce
        "${config.services.frp.package}/bin/frpc --strict_config -c /run/frp-frpc/frpc.toml";
    };
    preStart = ''
      sed 's/''${FRPC_TOKEN}/'"$FRPC_TOKEN"'/g' ${frpcBaseToml} > /run/frp-frpc/frpc.toml
    '';
  };
}
