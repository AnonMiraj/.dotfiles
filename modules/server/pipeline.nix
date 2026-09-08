{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.server.bosla.enable {
    # bosla roadmap pipeline (FastAPI + Socket.IO on :7860).
    # Image is built locally from the source in `/opt/bosla-pipeline` (a durable
    # copy of the app that migrated from ephemeral /tmp) — no external registry.
    # A build step (`docker build`) runs before start, so the image always matches
    # the source currently on disk. Keep `/opt/bosla-pipeline/src` + Dockerfile in
    # sync when the app changes; push/build on a registry is a future option once
    # the self-hosted runner has a token.

    systemd.services.bosla-pipeline = {
      description = "bosla roadmap pipeline (FastAPI :7860)";
      after = ["docker.service" "network-online.target"];
      wants = ["docker.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # Build from the durable source (layers are cached, so this is cheap when
        # /opt/bosla-pipeline is unchanged).
        ExecStartPre = [
          "${pkgs.docker}/bin/docker rm -f bosla-pipeline || true"
          "${pkgs.docker}/bin/docker build -t bosla-pipeline:almiraj /opt/bosla-pipeline"
        ];
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