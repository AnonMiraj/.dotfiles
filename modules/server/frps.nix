{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.server.frps.enable {
    # frp server — terminates frp tunnels from home `niro` (kept: home services
    # are exposed publicly through it). Config → sops.
    #
    # TODO(Phase 3): from /etc/frps.toml + home selfhost frp client routes:
    # - services.frp? (pkgs.frp) systemd unit with frps -c <sops path>
    # - the selfhost two-site refactor must emit BOTH sides consistently:
    #   home frpc routes → VPS frps listener remote ports
    # - open the frp listener port in the firewall
  };
}