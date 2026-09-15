{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf filterAttrsToList nameValuePair attrNames;

  # Cloudflare edge ranges (cloudflare.com/ips-v4 + ips-v6). Requests from
  # these get the real client IP parsed from the CF headers, so access logs
  # (and anything else IP-based) see visitors instead of CF edge IPs.
  cloudflareRanges = [
    "173.245.48.0/20"
    "103.21.244.0/22"
    "103.22.200.0/22"
    "103.31.4.0/22"
    "141.101.64.0/18"
    "108.162.192.0/18"
    "190.93.240.0/20"
    "188.114.96.0/20"
    "197.234.240.0/22"
    "198.41.128.0/17"
    "162.158.0.0/15"
    "104.16.0.0/13"
    "104.24.0.0/14"
    "172.64.0.0/13"
    "131.0.72.0/22"
    "2400:cb00::/32"
    "2606:4700::/32"
    "2803:f800::/32"
    "2405:b500::/32"
    "2405:8100::/32"
    "2a06:98c0::/29"
    "2c0f:f248::/32"
  ];
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
    status = "gatus";
    qb = "qbittorrent";
    analytics = "goatcounter";
    cashflow = "cashflow";
  };
  enabled = name: config.my.server.${stackOf.${name}}.enable;
in
mkIf config.my.server.public {
  services.caddy = {
    enable = true;
    globalConfig = lib.mkAfter ''
      servers {
        trusted_proxies static ${lib.concatStringsSep " " cloudflareRanges}
        trusted_proxies_strict
      }
    '';
    # vpn.almiraj.xyz is custom (panel + VLESS ws split), so it's added
    # explicitly below and excluded from the generic generator.
    virtualHosts = let
      others = attrNames (lib.filterAttrs (name: svc:
        enabled name && name != "3xui-panel"
      ) config.my.publicServices);
    in
      (builtins.listToAttrs
        (map (name: nameValuePair config.my.publicServices.${name}.domain {
          extraConfig = let
            svc = config.my.publicServices.${name};
          in ''
            ${lib.optionalString svc.auth ''
              # tinyauth login (see modules/server/tinyauth.nix for the
              # per-app path exceptions).
              forward_auth 127.0.0.1:${toString config.my.server.tinyauth.port} {
                uri /api/auth/caddy
              }
            ''}
            reverse_proxy ${targetOf svc}
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
      # Dashboard behind tinyauth; /count, /count.js and /api/v0/count stay
      # public (site trackers + backend pushes) via the allowlist in
      # modules/server/tinyauth.nix.
      auth = true;
    };
  };
}