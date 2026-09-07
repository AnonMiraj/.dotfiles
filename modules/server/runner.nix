{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.server.runner.enable {
    # GitHub self-hosted runner (Bosla-Ai) — runs on the VPS (arm64).
    # Doubles as the arm64 build + CI deployer for this flake (pSub pattern):
    # it can `nix flake check`, build `.#almiraj`, and deploy.
    #
    # TODO(Phase 3):
    # - github-runners / actions-runner systemd service (token → sops)
    # - runner repo: Bosla-Ai
    # - also builds arm64 docker images for bosla
    # - add a Justfile/CI path so the runner deploys .#almiraj on push
  };
}