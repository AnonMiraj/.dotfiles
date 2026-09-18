{
  config,
  lib,
  pkgs,
  ...
}: let
  localPort = 18091;
  remotePort = 8091;
  vps = "admin@ssh.almiraj.xyz";
  mountPoint = "${config.home.homeDirectory}/vps";
  # Hiddify mixed SOCKS/HTTP proxy. The PS zero-rating only applies to bytes
  # that cross the VLESS/WS tunnel; Hiddify excludes the VPN server IP from the
  # TUN, so a direct ssh to the VPS is metered. Tunnelling ssh through the
  # mixed port puts the transfer inside the VLESS tunnel.
  hiddifyMixedPort = 12334;
in {
  # Read-only view of the almiraj downloads. The public dl.almiraj.xyz vhost
  # is the browser path (tinyauth); this machine path reaches the VPS loopback
  # rclone server through an ssh local forward, so no extra credentials.
  home.packages = [pkgs.rclone];

  xdg.configFile."rclone/rclone.conf".text = ''
    [almiraj]
    type = webdav
    url = http://127.0.0.1:${toString localPort}
    vendor = other
  '';

  systemd.user.services.rclone-webdav-tunnel = {
    Unit = {
      Description = "ssh local forward to the almiraj rclone WebDAV server";
    };
    Service = {
      ExecStart = "${pkgs.openssh}/bin/ssh -N -o BatchMode=yes -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o IdentitiesOnly=yes -o \"ProxyCommand=${pkgs.netcat-openbsd}/bin/nc -X 5 -x 127.0.0.1:${toString hiddifyMixedPort} %%h %%p\" -i %h/.ssh/id_ed25519 -L 127.0.0.1:${toString localPort}:127.0.0.1:${toString remotePort} ${vps}";
      Restart = "always";
      RestartSec = "5s";
    };
    Install.WantedBy = ["default.target"];
  };

  systemd.user.services.rclone-webdav-mount = {
    Unit = {
      Description = "Mount the almiraj downloads over rclone WebDAV";
      After = ["rclone-webdav-tunnel.service"];
      Requires = ["rclone-webdav-tunnel.service"];
      PartOf = ["rclone-webdav-tunnel.service"];
    };
    Service = {
      Type = "simple";
      Environment = "PATH=/run/wrappers/bin:${pkgs.rclone}/bin";
      ExecStartPre = [
        "-/run/wrappers/bin/fusermount3 -uz ${mountPoint}"
        "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}"
      ];
      ExecStart = "${pkgs.rclone}/bin/rclone mount almiraj: ${mountPoint} --read-only --vfs-cache-mode off --dir-cache-time 1m --log-level INFO";
      ExecStop = "-/run/wrappers/bin/fusermount3 -uz ${mountPoint}";
      Restart = "on-failure";
      RestartSec = "10s";
    };
    Install.WantedBy = ["default.target"];
  };
}
