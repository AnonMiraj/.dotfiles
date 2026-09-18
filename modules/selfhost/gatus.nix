# Local Gatus instance: web config plus endpoints generated from my.services.
{
  config,
  lib,
  ...
}: let
  h = import ../../lib/selfhost.nix {inherit lib config;};
  inherit (lib) filterAttrs mapAttrsToList;
  inherit (h) displayName domainOf groupOf;
in {
  services.gatus = {
    enable = true;
    openFirewall = false;
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
        title = "Status | niro";
        description = "Service health monitoring";
      };
      endpoints = mapAttrsToList (name: svc: {
        name = displayName name svc;
        group = groupOf svc;
        url = "https://${domainOf svc}${svc.gatus.checkPath}";
        interval = "30s";
        conditions = svc.gatus.conditions;
        client = {insecure = true;};
      }) (filterAttrs (_: svc: svc.gatus.enable) config.my.services);
    };
  };
}
