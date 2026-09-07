{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.server."3x-ui".enable {
    # 3x-ui VPN/panel container — grey-area proxy, kept containerized per plan.
    #
    # TODO(Phase 3): from /root/3x-ui:
    # - copy /root/3x-ui/db/* (sqlite) + /root/3x-ui/cert/* → persistent dataset
    # - ports: VLESS ws 10001, panel 2053, subs 2096 (+ the handful actually used)
    # - Caddy vhosts: vpn.almiraj.xyz + playstation.net/*.sony.com spoof hosts,
    #   static /var/www/html landing
    # - panel binds localhost → reach via SSH tunnel / tailscale (hardening §7)
    # - envelope these ports explicitly in the firewall, nothing else
  };
}