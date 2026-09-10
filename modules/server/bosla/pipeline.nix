{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.server.bosla.enable {
    # Keep the local ARM64 image and existing systemd unit name. pull=never
    # lets oci-containers manage this image without contacting a registry.
    # bosla-deploy selects the exact commit; the current image is pre-tagged
    # locally as this :latest so restarts never rebuild over it.
    virtualisation.oci-containers.containers.bosla-pipeline = {
      image = "bosla26/bosla-pipeline:latest";
      serviceName = "bosla-pipeline";
      pull = "never";
      networks = ["bosla-internal"];
      ports = ["7860:7860"];
      environmentFiles = ["/run/bosla-pipeline/environment"];
      environment = {
        ENVIRONMENT = "production";
        ALLOW_DEV_AUTH_BYPASS = "false";
      };
      extraOptions = [
        "--health-cmd=python -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:7860/health', timeout=4)\""
        "--health-interval=30s"
        "--health-timeout=5s"
        "--health-start-period=30s"
        "--health-retries=3"
      ];
    };

    systemd.services.bosla-pipeline = {
      after = ["bosla-network.service" "sops-nix.service"];
      requires = ["bosla-network.service"];
      serviceConfig = {
        RuntimeDirectory = "bosla-pipeline";
        RuntimeDirectoryMode = "0700";
        ExecStartPre = lib.mkBefore [
          "${pkgs.python3}/bin/python3 ${./bosla-pipeline-env.py}"
        ];
      };
    };

    services.caddy.virtualHosts."pipeline.almiraj.xyz" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:7860
      '';
    };
  };
}
