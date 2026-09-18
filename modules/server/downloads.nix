{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.server.downloads;
  downloadsDir = "/var/lib/qbittorrent/downloads";
in {
  options.my.server.downloads = {
    enable = lib.mkEnableOption "read-only WebDAV server for completed qBittorrent downloads";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8091;
      description = "Loopback port rclone serves WebDAV on.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.rclone = {};
    users.users.rclone = {
      isSystemUser = true;
      group = "rclone";
      extraGroups = ["qbittorrent" "aria2"];
      description = "rclone WebDAV server";
    };

    systemd.services.rclone-webdav = {
      description = "rclone WebDAV server for completed downloads";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "simple";
        User = "rclone";
        Group = "rclone";
        ExecStart = "${pkgs.rclone}/bin/rclone serve webdav ${downloadsDir} --addr 127.0.0.1:${toString cfg.port} --read-only --exclude '/.incomplete/**' --exclude '*.parts' --dir-cache-time 1m --log-level INFO";
        Restart = "on-failure";
        RestartSec = "5s";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadOnlyPaths = [downloadsDir];
        RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
      };
    };

    # Browser-facing WebDAV over TLS, gated by tinyauth like the other
    # private vhosts. The machine-facing path is the loopback port, reached
    # from niro through an ssh local forward (see users/nir/rclone.nix).
    my.publicServices.dl = {
      domain = "dl.almiraj.xyz";
      port = cfg.port;
      checkPath = "/";
      group = "media";
      stack = "downloads";
      auth = true;
    };
  };
}
