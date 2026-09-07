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
      };
    };
  };
}