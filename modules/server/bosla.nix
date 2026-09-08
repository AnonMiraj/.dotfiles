{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.server.bosla.enable {
    # bosla stack — docker containers on the VPS (shared engine from base.nix).
    # Images may be org-built (bosla26/*) and rebuilt for arm64 by the VPS
    # self-hosted runner; tag `:latest` is substituted for pinned digests in
    # Phase 3.
    #
    # Secrets: full bosla `.env` (sops bosla-env) is injected into the api
    # container. Frontend + typst-worker need no secrets.
    # Caddy hostnames come from modules/server/public.nix (public.enable).

    sops.secrets.bosla-env = {path = "/run/secrets/bosla-env";};

    virtualisation.oci-containers = {
      backend = "docker";
      containers = {
        bosla-api = {
          image = "bosla26/bosla-api:latest";
          ports = ["5280:8080"];
          environmentFiles = ["/run/secrets/bosla-env"];
        };
        bosla-frontend = {
          image = "bosla26/bosla-frontend:latest";
          ports = ["3001:80"];
        };
        typst-worker = {
          image = "bosla26/typst-worker:latest";
          # the image's baked healthcheck tests a typst binary path that isn't in
          # the image -> falsely 'unhealthy'. The worker runs fine; disable it.
          extraOptions = ["--no-healthcheck"];
        };
      };
    };
  };
}