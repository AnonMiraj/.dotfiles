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
        ports = [
          "2053:2053"
          "10001:10001"
          "2096:2096"
        ];
        volumes = [
          "/var/lib/3x-ui/db:/etc/x-ui"
        ];
        environment = {
          XRAY_DISABLE_SYSTEMD = "true";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [2053 10001 2096];
  };
}