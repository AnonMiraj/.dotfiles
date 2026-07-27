{ inputs, pkgs }:
inputs.subminer.packages.${pkgs.stdenv.hostPlatform.system}.default
