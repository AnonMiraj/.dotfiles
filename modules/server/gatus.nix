{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.server.gatus.enable {
    # gatus uptime monitor — declarative on the VPS (status.niro.almiraj.xyz).
    # Home `niro` pushes service health into it via external-endpoints.
    #
    # TODO(Phase 3):
    # - reuse modules/selfhost/gatus.nix origin/config on the almiraj site,
    #   replacing the hand-edited /root/gatus/config.yaml (deletes the manual
    #   AGENTS.md step)
    # - keep external-endpoints matching the push keys from home (core_, media_, …)
    # - Caddy vhost status.niro.almiraj.xyz (LE tls)
  };
}