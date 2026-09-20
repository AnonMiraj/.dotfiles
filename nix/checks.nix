{
  self,
  lib,
  ...
}: {
  perSystem = {pkgs, ...}: let
    nixos = self.nixosConfigurations.niro.config;
    hmFiles = nixos.home-manager.users.nir.xdg.configFile;

    # Everything Home Manager drops into ~/.config/hypr. hyprland.lua does
    # `require("hyprsplit-init")`, which in turn requires `hyprsplit`, so the
    # whole directory has to be present - otherwise the Lua chunk fails to load,
    # and a missing module looks just like a config error.
    hyprDir = pkgs.linkFarm "hyprland-config" (
      lib.mapAttrsToList (name: file: {
        name = lib.removePrefix "hypr/" name;
        path = file.source;
      }) (lib.filterAttrs (name: _: lib.hasPrefix "hypr/" name) hmFiles)
    );
  in {
    # `Hyprland --verify-config` parses the config and reports the result, so a
    # typo'd or removed key fails `nix flake check` instead of the next login.
    #
    # It cannot validate plugin options. CCompositor::initServer returns before
    # g_pPluginSystem exists, so a plugin has not registered its keys yet and
    # every settings.config.plugin.* key is reported as unknown; at runtime
    # handlePluginLoads() dlopens the plugins and reloads, reparsing with those
    # keys present. Those specific lines are therefore dropped, and anything
    # else still fails the check.
    checks.hyprland-config =
      pkgs.runCommand "check-hyprland-config" {
        nativeBuildInputs = [nixos.programs.hyprland.package];
      } ''
        export HOME=$TMPDIR
        export XDG_CONFIG_HOME=$TMPDIR/.config
        export XDG_RUNTIME_DIR=$TMPDIR/runtime
        mkdir -p "$XDG_CONFIG_HOME/hypr" "$XDG_RUNTIME_DIR"
        cp -rL ${hyprDir}/. "$XDG_CONFIG_HOME/hypr/"

        # `--verify-config` parses the config and exits without ever starting
        # the event loop, but the Lua config manager destroys its timers on the
        # way out (CConfigManager::cleanTimers -> CEventLoopManager::
        # removeTimer) and dereferences that unstarted loop as soon as the
        # config registered one: exit 139 with no parsing result at all.
        # Scrolloverview's repeating timer does that, so stub the constructor
        # out before the config runs. Timing cannot be checked here anyway, and
        # every other hl.* call still goes through the real parser.
        printf '%s\n' 'hl.timer = function() return {} end' > hyprland.lua.stub
        cat "$XDG_CONFIG_HOME/hypr/hyprland.lua" >> hyprland.lua.stub
        mv hyprland.lua.stub "$XDG_CONFIG_HOME/hypr/hyprland.lua"

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
