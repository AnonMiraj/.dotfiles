{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.server.gatus.enable {
    # gatus uptime monitor (status.niro.almiraj.xyz). Serves the health checks
    # pushed from home `niro` (external-endpoints keyed `group_Name`) plus its
    # own local checks. Existing config is in backup root-gatus/config.yaml —
    # migrate its external-endpoints + auth into this module in Phase 3.
    #
    # Tokens used by the home push come from the push-status side (niro); the
    # matching token keys live in secrets (home secrets.yaml), so nothing secret
    # is needed here beyond the config grant.
    services.gatus = {
      enable = true;
      openFirewall = false; # fronted by Caddy (public.nix `status`)
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
        # external-endpoints = [ ... ];   # wire from backup config.yaml in Phase 3
        # At least one endpoint is required for gatus to start.
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
        ];
        # Home (niro) services — updated by the home push-status timer via the
        # status.niro.almiraj.xyz endpoint. Tokens match home secrets.
        external-endpoints = [
          { name = "Bazarr"; group = "media"; token = "tok_bazarr_e5k8s2p4"; }
          { name = "File Server"; group = "media"; token = "tok_fileserver_f3t7w9n1"; }
          { name = "FlareSolverr"; group = "media"; token = "tok_flaresolverr_a7x3k9m2"; }
          { name = "System Monitor"; group = "system"; token = "tok_glances_g2b6r8x4"; }
          { name = "Homepage"; group = "core"; token = "tok_homepage_a7x3k9m2"; }
          { name = "Jellyfin"; group = "media"; token = "tok_jellyfin_b4r8p1n5"; }
          { name = "Kokoro TTS"; group = "dev"; token = "tok_kokoro_k1t5x7n3"; }
          { name = "Paseo"; group = "dev"; token = "tok_paseo_h5n1k3v7"; }
          { name = "Prowlarr"; group = "media"; token = "tok_prowlarr_b8y4l0n3"; }
          { name = "Sonarr"; group = "media"; token = "tok_sonarr_d9m4n1x7"; }
          { name = "Transmission"; group = "media"; token = "tok_transmission_c2v6w3q8"; }
        ];

      };
    };
  };
}