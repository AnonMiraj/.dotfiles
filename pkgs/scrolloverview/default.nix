# Scrollable workspace overview for Hyprland, "just like niri".
#
# Not in nixpkgs, so it is built from source here. The important property:
# `mkHyprlandPlugin` is handed this repo's `pkgs.hyprland`, i.e. the exact
# Hyprland the session runs (0.56.2). Plugins declare
# `PLUGIN_API_VERSION() { return HYPRLAND_API_VERSION; }` and Hyprland verifies it
# on load, so building against a mismatched Hyprland is a build failure rather
# than a compositor crash. Upstream's own hyprpm pins stop at v0.55.4, so this
# build is the real compatibility check.
#
# Upstream flake.nix is the reference for these phases; the Makefile does not use
# CMake and does not install anything itself, hence the hand-written installPhase.
{
  lib,
  fetchFromGitHub,
  lua5_4,
  mkHyprlandPlugin,
}: let
  version = "unstable-2026-09-07";
in
  mkHyprlandPlugin {
    pluginName = "scrolloverview";
    inherit version;

    src = fetchFromGitHub {
      owner = "yayuuu";
      repo = "hyprland-scroll-overview";
      rev = "5e96ae20ec73c320248bcf3ff68b330bc1ed4152";
      hash = "sha256-clDeTM5itsJPvqpbEkbWUmuPROsz2+YUnTpqsjQDMqU=";
    };

    # The plugin links against Lua 5.4 to register hl.plugin.scrolloverview.*
    buildInputs = [lua5_4];

    enableParallelBuilding = true;
    dontUseCmakeConfigure = true;

    buildPhase = ''
      runHook preBuild
      export SCROLLOVERVIEW_BUILD_VERSION="${version}"
      make all
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib"
      mv scrolloverview.so "$out/lib/libscrolloverview.so"
      runHook postInstall
    '';

    meta = {
      description = "Scrollable workspace overview plugin for Hyprland";
      homepage = "https://github.com/yayuuu/hyprland-scroll-overview";
      license = lib.licenses.bsd3;
      platforms = lib.platforms.linux;
    };
  }
