{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.server."3x-ui".enable {
    # 3x-ui VPN proxy panel — kept containerized (grey-area proxy, per plan).
    # DB + TLS live in /var/lib/3x-ui/db (restored from backup x-ui.db).
    # Ports (from the old deployment): panel 2053, VLESS ws 10001, subs 2096.
    # The panel binds localhost-facing; Caddy vhosts vpn.almiraj.xyz (public.nix).

    users.users.threexui = {
      isSystemUser = true;
      group = "threexui";
    };
    users.groups.threexui = {};

    virtualisation.oci-containers = {
      backend = "docker";
      containers."3xui" = {
        image = "ghcr.io/mhsanaei/3x-ui:latest";
        volumes = [
          "/var/lib/3x-ui/db:/etc/x-ui"
        ];
        extraOptions = ["--network host"]; # panel binds 127.0.0.1:2053 in-container; host-net makes it Caddy's loopback
        environment = {
          XRAY_DISABLE_SYSTEMD = "true";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [2053 10001 2096];
  };
}