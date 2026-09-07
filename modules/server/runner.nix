{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.server.runner.enable {
    # GitHub self-hosted runner for the Bosla-Ai org, running on the VPS (arm64).
    # Doubles as the aarch64 build + CI deployer for this flake (pSub pattern):
    # it can `nix flake check`, build `.#almiraj`, and deploy on push.
    #
    # tokenFile comes from sops (token registered in Phase 3).
    sops.secrets.github-runner-token = {path = "/run/secrets/github-runner-token";};

    services.github-runners.instances.bosla = {
      enable = true;
      # Org-level runner covering all Bosla-Ai repos. Set the exact org URL and
      # register/accept the token in GitHub during Phase 3.
      url = "https://github.com/Bosla-Ai";
      name = "Bosla-Ai";
      tokenFile = "/run/secrets/github-runner-token";
      extraLabels = ["linux" "arm64" "almiraj"];
      # nix + git so this runner can build/deploy the flake (arm64 builder)
      extraPackages = with pkgs; [
        nix
        git
        openssh
      ];
    };
  };
}