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
    "bosla-api" = "bosla";
    "bosla-frontend" = "bosla";
    "bosla-me" = "bosla";
    "3xui-panel" = "3x-ui";
    cashflow = "cashflow";
    status = "gatus";
    qb = "qbittorrent";
    analytics = "goatcounter";
  };
  enabled = name: config.my.server.${stackOf.${name}}.enable;
in
mkIf config.my.server.public {
  services.caddy = {
    enable = true;
    # vpn.almiraj.xyz is custom (panel + VLESS ws split), so it's added
    # explicitly below and excluded from the generic generator.
    virtualHosts = let
      others = attrNames (lib.filterAttrs (name: svc:
        enabled name && name != "3xui-panel"
      ) config.my.publicServices);
    in
      (builtins.listToAttrs
        (map (name: nameValuePair config.my.publicServices.${name}.domain {
          extraConfig = ''
            reverse_proxy ${targetOf config.my.publicServices.${name}}
          '';
        }) others))
      // {
        # 3x-ui: WebSocket VLESS (/vless) → loopback inbound :10001; rest → panel :2053
        "vpn.almiraj.xyz" = {
          extraConfig = ''
            handle /vless* {
              reverse_proxy 127.0.0.1:10001
            }
            handle {
              reverse_proxy 127.0.0.1:2053
            }
          '';
        };

        "http://playstation.net, http://*.playstation.net, http://playstation.com, http://*.playstation.com, http://sony.com, http://*.sony.com, http://152.53.81.54, http://ssh.almiraj.xyz" = {
          extraConfig = ''
            handle /vless* {
              reverse_proxy 127.0.0.1:10001
            }
            handle {
              respond "OK" 200
            }
          '';
        };
      };
  };

  networking.firewall.allowedTCPPorts = [80 443];

  my.publicServices = {

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
      domain = "status.almiraj.xyz";
      port = 8099;
      checkPath = "/";
      group = "system";
    };

    analytics = {
      domain = "analytics.almiraj.xyz";
      port = 8050;
      checkPath = "/status";
      group = "system";
      openFirewall = false; # GoatCounter binds 127.0.0.1; Caddy fronts it
    };
  };
}