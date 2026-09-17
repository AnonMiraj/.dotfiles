{
  self,
  lib,
  ...
}: {
  perSystem = {pkgs, ...}: let
    nixos = self.nixosConfigurations.niro.config;
    hmFiles = nixos.home-manager.users.nir.xdg.configFile;

    # Everything Home Manager drops into ~/.config/hypr; hyprland.lua requires
    # its siblings, so the whole directory has to be staged.
    hyprDir = pkgs.linkFarm "hyprland-config" (
      lib.mapAttrsToList (name: file: {
        name = lib.removePrefix "hypr/" name;
        path = file.source;
      }) (lib.filterAttrs (name: _: lib.hasPrefix "hypr/" name) hmFiles)
    );
  in {
    # Runs Hyprland --verify-config over the generated config, so a typo'd or
    # removed key fails `nix flake check` instead of the next login.
    #
    # Plugin keys are dropped: verify runs before the plugin system exists, so
    # settings.config.plugin.* always reports as unknown there while being valid
    # at runtime.
    checks.hyprland-config =
      pkgs.runCommand "check-hyprland-config" {
        nativeBuildInputs = [nixos.programs.hyprland.package];
      } ''
        export HOME=$TMPDIR
        export XDG_CONFIG_HOME=$TMPDIR/.config
        export XDG_RUNTIME_DIR=$TMPDIR/runtime
        mkdir -p "$XDG_CONFIG_HOME/hypr" "$XDG_RUNTIME_DIR"
        cp -rL ${hyprDir}/. "$XDG_CONFIG_HOME/hypr/"

        export HYPRLAND_CONFIG=$XDG_CONFIG_HOME/hypr/hyprland.lua
        export LUA_PATH="$XDG_CONFIG_HOME/hypr/?.lua;$XDG_CONFIG_HOME/hypr/?/init.lua;;"

        set +e
        Hyprland --verify-config >verify.log 2>&1
        status=$?
        set -e

        cat verify.log

        # Parse errors are reported as "<config path>:<line>: <message>".
        grep -E '^/.*hyprland\.lua:[0-9]+: ' verify.log \
          | grep -v "unknown config key 'plugin\." >errors.log || true

        if [ -s errors.log ]; then
          echo "=== hyprland config errors ==="
          cat errors.log
          exit 1
        fi

        if [ "$status" -ne 0 ] && ! grep -q 'Config parsing result' verify.log; then
          echo "=== Hyprland exited $status without reporting a parsing result ==="
          exit 1
        fi

        touch $out
      '';
  };
}
