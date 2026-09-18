{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.server.aria2;
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

    # AriaNg UI plus the JSON-RPC path, behind tinyauth. The RPC secret is
    # entered in AriaNg (Settings) or passed in its URL.
    services.caddy.virtualHosts."aria.almiraj.xyz" = {
      extraConfig = ''
        forward_auth 127.0.0.1:${toString config.my.server.tinyauth.port} {
          uri /api/auth/caddy
        }
        handle /jsonrpc* {
          reverse_proxy 127.0.0.1:${toString cfg.port}
        }
        handle {
          root * ${pkgs.ariang}/share/ariang
          file_server
        }
      '';
    };
  };
}
