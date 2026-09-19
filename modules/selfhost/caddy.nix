# Caddy vhosts, generated from my.services plus the fixed my.caddy.extraVhosts.
#
# Every vhost uses the shared `*.${domain}` certificate declared in
# modules/selfhost/acme.nix (Let's Encrypt DNS-01 via Cloudflare). Caddy reads
# the cert straight out of /var/lib/acme, so the old mkcert files are unused.
{
  config,
  lib,
  pkgs,
  ...
}: let
  h = import ../../lib/selfhost.nix {inherit lib config;};
  inherit (lib) mapAttrsToList nameValuePair;
  inherit (h) domain domainOf acmeHost;

  statusHost = "status.${domain}";
  homeHost = "home.${domain}";
  paseoHost = "paseo.${domain}";
  ariaHost = "aria.${domain}";

  # AriaNg copy whose index.html loads /rpc-preset.js before the app
  # boots, so the RPC target is configured on first visit instead of
  # being typed in by hand.
  ariangPreset = pkgs.runCommand "ariang-rpc-preset" {} ''
    cp -r ${pkgs.ariang}/share/ariang $out
    chmod -R u+w $out
    substituteInPlace $out/index.html \
      --replace '</head>' '<script src="/rpc-preset.js"></script></head>'
  '';

  mkVhost = name: vh:
    nameValuePair name {
      useACMEHost = acmeHost;
      extraConfig = ''
        reverse_proxy ${vh.proxyTarget}
      '';
    };

  extras = [
    (mkVhost domain config.my.caddy.extraVhosts.${domain})
    (mkVhost statusHost config.my.caddy.extraVhosts.${statusHost})
    (mkVhost homeHost config.my.caddy.extraVhosts.${homeHost})
    # Paseo — custom path routing
    (nameValuePair paseoHost {
      useACMEHost = acmeHost;
      extraConfig = ''
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
      useACMEHost = acmeHost;
      extraConfig = ''
        handle /rpc-preset.js {
          root * ${builtins.dirOf config.sops.templates."rpc-preset.js".path}
          file_server
        }
        handle /jsonrpc* {
          reverse_proxy localhost:6800
        }
        handle {
          root * ${ariangPreset}
          file_server
        }
      '';
    })
  ];

  generated = mapAttrsToList (name: svc:
    nameValuePair (domainOf svc) {
      useACMEHost = acmeHost;
      extraConfig = ''
        reverse_proxy ${
          if svc.proxyTarget != null
          then svc.proxyTarget
          else "localhost:${toString svc.port}"
        }
      '';
    })
  config.my.services;
in {
  # Seeded into AriaNg localStorage on first load. It points AriaNg at
  # Caddy on 443 instead of aria2's loopback 6800, then lets AriaNg's
  # own command API save the setting and return to the task list.
  sops.templates."rpc-preset.js" = {
    content = ''
      (function () {
        var raw = ${builtins.toJSON config.sops.placeholder."aria2-rpc-secret"};
        var std = btoa(raw);
        var url = std.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
        try {
          var o = JSON.parse(localStorage.getItem("AriaNg.Options") || "null");
          if (o && o.rpcHost === location.hostname && o.rpcPort === "443" &&
              o.protocol === "https" && o.rpcInterface === "jsonrpc" &&
              o.secret === std) {
            return;
          }
        } catch (e) {}
        if (sessionStorage.getItem("ariaNgPresetTried")) return;
        sessionStorage.setItem("ariaNgPresetTried", "1");
        location.hash = "#!/settings/rpc/set/https/" + location.hostname +
          "/443/jsonrpc/" + url;
      })();
    '';
    owner = config.services.caddy.user;
    mode = "0400";
  };

  services.caddy = {
    enable = true;
    virtualHosts = builtins.listToAttrs (extras ++ generated);
  };
}
