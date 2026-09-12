{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.server.gatus.enable {
    # Home push tokens come from the VPS sops secret `gatus-tokens`; they're
    # loaded as env vars via environmentFile and interpolated by gatus at
    # runtime (nothing secret is committed here).
    sops.secrets.gatus-tokens = {path = "/run/secrets/gatus-tokens";};

    services.gatus = {
      enable = true;
      openFirewall = false; # fronted by Caddy (public.nix `status`)
      environmentFile = "/run/secrets/gatus-tokens";
      settings = {
        web = {
          port = 8099;
          address = "127.0.0.1";
        };
        storage = {
          type = "sqlite";
          path = "/var/lib/gatus/data.db";
        };
        ui = {
          title = "Status | almiraj";
          description = "Service health monitoring";
        };
        endpoints = [
          {
            name = "almiraj blog";
            group = "web";
            url = "https://almiraj.xyz";
            interval = "1m";
            conditions = ["[STATUS] == 200"];
            client = {insecure = true;}; # behind Cloudflare/origin
          }
          {
            name = "status";
            group = "system";
            url = "http://127.0.0.1:8099";
            interval = "1m";
            conditions = ["[STATUS] == 200"];
          }
          {
            name = "aldebaran";
            group = "web";
            url = "https://aldebaran.moe";
            interval = "1m";
            conditions = ["[STATUS] == 200"];
            client = {insecure = true;};
          }
          {
            name = "cashflow";
            group = "games";
            url = "http://127.0.0.1:3100/api/health";
            interval = "1m";
            conditions = ["[STATUS] == 200"];
          }
        ];
        # Token values are injected at runtime from the `gatus-tokens` env vars.
        external-endpoints = [
          { name = "Bazarr"; group = "media"; token = "\${GATUS_BAZARR_TOKEN}"; }
          { name = "File Server"; group = "media"; token = "\${GATUS_FILESERVER_TOKEN}"; }
          { name = "FlareSolverr"; group = "media"; token = "\${GATUS_FLARESOLVERR_TOKEN}"; }
          { name = "System Monitor"; group = "system"; token = "\${GATUS_GLANCES_TOKEN}"; }
          { name = "Homepage"; group = "core"; token = "\${GATUS_HOMEPAGE_TOKEN}"; }
          { name = "Jellyfin"; group = "media"; token = "\${GATUS_JELLYFIN_TOKEN}"; }
          { name = "Kokoro TTS"; group = "dev"; token = "\${GATUS_KOKORO_TOKEN}"; }
          { name = "Paseo"; group = "dev"; token = "\${GATUS_PASEO_TOKEN}"; }
          { name = "Prowlarr"; group = "media"; token = "\${GATUS_PROWLARR_TOKEN}"; }
          { name = "Sonarr"; group = "media"; token = "\${GATUS_SONARR_TOKEN}"; }
          { name = "Transmission"; group = "media"; token = "\${GATUS_TRANSMISSION_TOKEN}"; }
        ];

      };
    };
  };
}