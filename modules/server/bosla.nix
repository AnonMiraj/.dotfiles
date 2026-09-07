{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.server.bosla.enable {
    # bosla stack (frontend, api, typst-worker) — docker containers on the VPS,
    # run under the shared docker engine (modules/base.nix) and defined via
    # compose2nix so the flake owns the compose → systemd conversion.
    #
    # TODO(Phase 3): from /home/moha/bosla-deployment + inventory:
    # - bosla .env (dozens of live API keys) → sops, never plaintext
    # - ports: frontend 3001→80, api 5280→8080, typst-worker
    # - GH Actions build arm64 images (runner on the VPS produces them)
    # - Caddy vhosts: bosla.almiraj.xyz / front.bosla.almiraj.xyz / bosla.me,
    #   bosla-pipeline 7443→7860
    # - docker named volumes persist under rpool/local/docker (ZFS dataset)
    # Placeholder: pending compose2nix generation in Phase 3.
  };
}