{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf filterAttrsToList nameValuePair attrNames;
  targetOf = svc:
    if svc.proxyTarget != null
    then svc.proxyTarget
    else "localhost:${toString svc.port}";

  # Map each public service to the stack that gates it (my.server.<x>.enable).
  stackOf = {
    mail = "mail";
    "bosla-api" = "bosla";
    "bosla-frontend" = "bosla";
    "bosla-me" = "bosla";
    "3xui-panel" = "3x-ui";
    status = "gatus";
  };
  enabled = name: config.my.server.${stackOf.${name}}.enable;
in
mkIf config.my.server.public {
  services.caddy = {
    enable = true;
    virtualHosts =
      (builtins.listToAttrs
        (map (name: nameValuePair name {
          extraConfig = ''
            reverse_proxy ${targetOf config.my.publicServices.${name}}
          '';
        }) (attrNames (lib.filterAttrs (name: svc: enabled name) config.my.publicServices))));
  };

  networking.firewall.allowedTCPPorts = [80 443];

  # Public service registry — concrete domains/ports. Each entry is only exposed
  # when its owning stack is enabled (Phase 3). Multi-route hostnames (e.g.
  # bosla *:7443 pipeline, vpn VLESS :10001) need named matchers in Phase 3, so
  # they are NOT listed here to keep one Caddy vhost per hostname.
  my.publicServices = {
    mail = {
      domain = "mail.icpczagazig.org";
      port = 8080; # roundcube (G6a) behind Caddy
      checkPath = "/";
      group = "mail";
    };

    "bosla-api" = {
      domain = "bosla.almiraj.xyz";
      port = 5280;
      proxyTarget = "localhost:5280";
      checkPath = "/";
      group = "bosla";
    };
    "bosla-frontend" = {
      domain = "front.bosla.almiraj.xyz";
      port = 3001;
      checkPath = "/";
      group = "bosla";
    };
    "bosla-me" = {
      domain = "bosla.me";
      port = 3001;
      checkPath = "/";
      group = "bosla";
    };

    "3xui-panel" = {
      domain = "vpn.almiraj.xyz";
      port = 2053;
      checkPath = "/";
      group = "vpn";
    };

    status = {
      domain = "status.niro.almiraj.xyz";
      port = 8099;
      checkPath = "/";
      group = "system";
    };
  };
}