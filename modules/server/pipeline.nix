{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.server.bosla.enable {
    # bosla roadmap pipeline (FastAPI + Socket.IO on :7860).
    # Local-only arm64 image `bosla-pipeline:almiraj` (built on the box), so it's
    # run via a systemd docker service (oci-containers would try to pull it).
    # External via Caddy at pipeline.almiraj.xyz.

    systemd.services.bosla-pipeline = {
      description = "bosla roadmap pipeline (FastAPI :7860)";
      after = ["docker.service" "network-online.target"];
      wants = ["docker.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStartPre = "${pkgs.docker}/bin/docker rm -f bosla-pipeline || true";
        ExecStart = "${pkgs.docker}/bin/docker run -d --name bosla-pipeline -p 7860:7860 --restart unless-stopped bosla-pipeline:almiraj";
        ExecStop = "${pkgs.docker}/bin/docker rm -f bosla-pipeline";
      };
    };

    services.caddy.virtualHosts."pipeline.almiraj.xyz" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:7860
      '';
    };
  };
}