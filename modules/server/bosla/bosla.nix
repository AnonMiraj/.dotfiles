{
  config,
  lib,
  pkgs,
  ...
}: let
  networkDependency = {
    after = ["bosla-network.service" "sops-nix.service"];
    requires = ["bosla-network.service"];
  };
in {
  config = lib.mkIf config.my.server.bosla.enable {
    # NixOS owns container lifecycle; bosla-deploy selects an exact image and
    # updates the local tag before restarting the corresponding systemd unit.
    sops.secrets.bosla-env = {
      path = "/run/secrets/bosla-env";
      restartUnits = ["docker-bosla-api.service" "bosla-pipeline.service"];
    };

    systemd.services.bosla-network = {
      description = "Docker network for Bosla service discovery";
      after = ["docker.service"];
      requires = ["docker.service"];
      wantedBy = ["multi-user.target"];
      path = [pkgs.docker];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        docker network inspect bosla-internal >/dev/null 2>&1 \
          || docker network create bosla-internal
      '';
      # Do not delete a live network on service stop or a NixOS switch.
    };

    # Start dependencies with the API without coupling their restart lifecycle:
    # deploying the worker must not stop the API as a Requires= dependency.
    systemd.services.docker-bosla-api =
      networkDependency
      // {
        after = networkDependency.after ++ ["docker-typst-worker.service" "bosla-pipeline.service"];
        wants = ["docker-typst-worker.service" "bosla-pipeline.service"];
      };
    systemd.services.docker-bosla-frontend = networkDependency;
    systemd.services.docker-typst-worker = networkDependency;

    virtualisation.oci-containers = {
      backend = "docker";
      containers = {
        bosla-api = {
          image = "bosla26/bosla-api:latest";
          pull = "never";
          networks = ["bosla-internal"];
          ports = ["5280:8080"];
          environmentFiles = ["/run/secrets/bosla-env"];
          environment = {
            TypstWorker__BaseUrl = "http://typst-worker:8080";
            # Legacy clients POST to the configured URL directly. Current tool
            # clients derive its origin and append /tools/* themselves.
            AI__PipelineApi__BaseUrl = "http://bosla-pipeline:7860/generate-roadmap";
            AI__PipelineApi__Mode = "HttpSync";
          };
        };
        bosla-frontend = {
          image = "bosla26/bosla-frontend:latest";
          pull = "never";
          networks = ["bosla-internal"];
          ports = ["3001:80"];
        };
        typst-worker = {
          image = "bosla26/typst-worker:latest";
          pull = "never";
          networks = ["bosla-internal"];
        };
      };
    };
  };
}
