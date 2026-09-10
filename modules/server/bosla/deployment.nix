{
  config,
  lib,
  pkgs,
  ...
}: let
  deploy = pkgs.writeShellApplication {
    name = "bosla-deploy";
    runtimeInputs = with pkgs; [coreutils util-linux docker systemd];
    text = builtins.readFile ./bosla-deploy.sh;
  };
in {
  config = lib.mkIf config.my.server.bosla.enable {
    environment.systemPackages = [deploy];
    security.sudo.extraRules = lib.mkIf config.my.server.runner.enable [
      {
        users = ["bosla-runner"];
        commands = [
          {
            command = "/run/current-system/sw/bin/bosla-deploy";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
  };
}
