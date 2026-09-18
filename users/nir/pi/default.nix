{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  piHashlineEdit = pkgs.buildNpmPackage rec {
    pname = "pi-hashline-edit";
    version = "0.6.0";

    src = pkgs.fetchFromGitHub {
      owner = "RimuruW";
      repo = "pi-hashline-edit";
      rev = "v${version}";
      hash = "sha256-ylpq7+rXDk2+c0Lvd73D1rkJ6onHo+1QiCiEbFA8MKY=";
    };

    postPatch = ''
      cp ${./pi-hashline-edit/package-lock.json} package-lock.json
      cp ${./pi-hashline-edit/package.json} package.json
    '';

    npmDepsHash = "sha256-3LimhPRzJm/EoQmbtGHfLtUMTNh7qRUt6DrPOENutAU=";
    dontNpmBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r index.ts src prompts README.md LICENSE node_modules $out/
      runHook postInstall
    '';
  };

  # Seed values for ~/.pi/agent/{settings,keybindings}.json. Pi owns these
  # files at runtime, so they are only written when missing (see activation).
  piSettings = builtins.toJSON {
    defaultProvider = "oc-sdk-go";
    defaultModel = "deepseek-v4.1-flash";
    hideThinkingBlock = false;
    defaultThinkingLevel = "low";
    steeringMode = "all";
    followUpMode = "all";
    enableInstallTelemetry = false;
    packages = [
      "npm:pi-opencode-bridge@0.2.1"
      "npm:@llblab/pi-telegram@0.44.0"
      "npm:@ff-labs/pi-fff@0.10.6"
      "git:github.com/AnonMiraj/pi-ask"
      "npm:@tintinweb/pi-tasks@0.9.0"
      "npm:@trevonistrevon/pi-loop@0.7.14"
      "npm:pi-web-access@0.28.0"
    ];
  };

  piKeybindings = builtins.toJSON {
    "tui.editor.cursorLeft" = ["left"];
    "tui.input.newLine" = ["shift+enter"];
    "app.models.clearAll" = ["ctrl+shift+x"];
  };
in {
  imports = [inputs.skills-flake.homeModules.default];

  home.packages = [
    inputs.llm-agents.packages.${pkgs.system}.pi
    inputs.llm-agents.packages.${pkgs.system}.skills
  ];

  # Pi writes these atomically on /settings, Ctrl+S, and `pi install`. Do not
  # force-symlink them into the read-only store: every write then fails and
  # leaves settings.json.tmp.* litter. Seed once, then let pi own the files.
  home.activation.piConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    pi_seed() {
      target="$1"
      default="$2"
      mkdir -p "$(dirname "$target")"
      # Replace any stale home-manager store symlink with a writable copy.
      if [ -L "$target" ]; then
        rm -f "$target"
      fi
      if [ ! -e "$target" ]; then
        printf '%s\n' "$default" > "$target"
      fi
    }

    pi_seed "$HOME/.pi/agent/settings.json" ${lib.escapeShellArg piSettings}
    pi_seed "$HOME/.pi/agent/keybindings.json" ${lib.escapeShellArg piKeybindings}
  '';

  home.file.".pi/agent/extensions" = {
    source = ./extensions;
    recursive = true;
  };

  home.file.".pi/agent/extensions/pi-hashline-edit" = {
    source = piHashlineEdit;
    recursive = true;
  };

  home.skillsFlake = {
    enable = true;
    agents.pi.enable = true;
    skills = {
      inherit (inputs.skills-flake.packages.${pkgs.system}.skills.github.juliusbrussee.caveman) caveman;
      inherit (inputs.skills-flake.packages.${pkgs.system}.skills.github.openclaw.openclaw) tmux;
    };
  };
}
