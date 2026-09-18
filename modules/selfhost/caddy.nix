# Caddy vhosts, generated from my.services plus the fixed my.caddy.extraVhosts.
{
  config,
  lib,
  pkgs,
  ...
}: let
  h = import ../../lib/selfhost.nix {inherit lib config;};
  inherit (lib) mapAttrsToList nameValuePair;
  inherit (h) domain domainOf tlsBlock;

  statusHost = "status.${domain}";
  homeHost = "home.${domain}";
  paseoHost = "paseo.${domain}";
  ariaHost = "aria.${domain}";

  mkVhost = name: vh:
    nameValuePair name {
      serverAliases = vh.serverAliases;
      extraConfig = ''
        ${tlsBlock}
        reverse_proxy ${vh.proxyTarget}
      '';
    };

  extras = [
    (mkVhost domain config.my.caddy.extraVhosts.${domain})
    (mkVhost statusHost config.my.caddy.extraVhosts.${statusHost})
    (mkVhost homeHost config.my.caddy.extraVhosts.${homeHost})
    # Paseo — custom path routing
    (nameValuePair paseoHost {
      serverAliases = config.my.caddy.extraVhosts.${paseoHost}.serverAliases;
      extraConfig = ''
        ${tlsBlock}
        handle /ws* { reverse_proxy localhost:6767 }
        handle /api* { reverse_proxy localhost:6767 }
        handle /mcp* { reverse_proxy localhost:6767 }
        handle /public* { reverse_proxy localhost:6767 }
        handle {
          root * /var/lib/paseo/web
          try_files {path} /index.html
          file_server
        }
      '';
    })
    # Aria2 / AriaNg — custom static web + RPC routing
    (nameValuePair ariaHost {
      serverAliases = ["*.${ariaHost}"];
      extraConfig = ''
        ${tlsBlock}
        handle /jsonrpc* {
          reverse_proxy localhost:6800
        }
        handle {
          root * ${pkgs.ariang}/share/ariang
          file_server
        }
      '';
    })
  ];

  generated = mapAttrsToList (name: svc:
    nameValuePair (domainOf svc) {
      serverAliases = ["*.${domainOf svc}"];
      extraConfig = ''
        ${tlsBlock}
        reverse_proxy ${
          if svc.proxyTarget != null
          then svc.proxyTarget
          else "localhost:${toString svc.port}"
        }
      '';
    })
  config.my.services;
in {
  services.caddy = {
    enable = true;
    virtualHosts = builtins.listToAttrs (extras ++ generated);
  };
}
