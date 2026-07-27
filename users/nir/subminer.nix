{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  subminerPkg = inputs.subminer.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  meta.maintainers = [ lib.maintainers.anonmiraj ];

  systemd.user.services.subminer = {
    Unit = {
      Description = "SubMiner background app (tray + IPC)";
      Documentation = "https://github.com/AnonMiraj/SubMiner";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${lib.getExe subminerPkg} app --background";
      Restart = "on-failure";
      RestartSec = "5";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
