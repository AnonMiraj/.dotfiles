{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.server.aria2;

  # AriaNg copy whose index.html loads /rpc-preset.js before the app
  # boots, so the RPC target is configured on first visit instead of
  # being typed in by hand.
  ariangPreset = pkgs.runCommand "ariang-rpc-preset" {} ''
    cp -r ${pkgs.ariang}/share/ariang $out
    chmod -R u+w $out
    substituteInPlace $out/index.html \
      --replace '</head>' '<script src="/rpc-preset.js"></script></head>'
  '';
in {
  options.my.server.aria2 = {
    enable = lib.mkEnableOption "aria2 + AriaNg download manager (aria.almiraj.xyz)";
    port = lib.mkOption {
      type = lib.types.port;
      default = 6800;
      description = "Loopback port aria2's JSON-RPC (and AriaNg) listen on.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.aria2-rpc-secret = {
      path = "/run/secrets/aria2-rpc-secret";
      restartUnits = ["aria2.service"];
    };

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

    # Downloads land inside the qBittorrent tree so the existing
    # rclone WebDAV server (modules/server/downloads.nix) exposes them
    # without a second server or a second mount.
    services.aria2 = {
      enable = true;
      rpcSecretFile = config.sops.secrets.aria2-rpc-secret.path;
      downloadDirPermission = "0770";
      serviceUMask = "0002";
      settings = {
        dir = "/var/lib/qbittorrent/downloads/aria2";
        rpc-listen-port = cfg.port;
        rpc-listen-all = false;
        rpc-allow-origin-all = true;
        continue = true;
        max-concurrent-downloads = 5;
        max-connection-per-server = 16;
        min-split-size = "10M";
        split = 16;
        enable-dht = true;
      };
    };

    # aria2 needs to traverse the qbittorrent-owned parent; rclone in
    # modules/server/downloads.nix joins the aria2 group to read the files.
    users.users.aria2.extraGroups = ["qbittorrent"];

    # AriaNg UI plus the JSON-RPC path, behind tinyauth. The RPC target
    # is preset by /rpc-preset.js so no manual AriaNg setup is needed.
    services.caddy.virtualHosts."aria.almiraj.xyz" = {
      extraConfig = ''
        forward_auth 127.0.0.1:${toString config.my.server.tinyauth.port} {
          uri /api/auth/caddy
        }
        handle /rpc-preset.js {
          root * ${builtins.dirOf config.sops.templates."rpc-preset.js".path}
          file_server
        }
        handle /jsonrpc* {
          reverse_proxy 127.0.0.1:${toString cfg.port}
        }
        handle {
          root * ${ariangPreset}
          file_server
        }
      '';
    };
  };
}
