{
  config,
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
in {
  imports = [inputs.skills-flake.homeModules.default];

  home.packages = [
    inputs.llm-agents.packages.${pkgs.system}.pi
    inputs.llm-agents.packages.${pkgs.system}.skills
  ];

  home.file.".pi/agent/settings.json" = {
    force = true;
    text = builtins.toJSON {
      defaultProvider = "oc-sdk-go";
      defaultModel = "oc-sdk-go/deepseek-v4-flash";
      hideThinkingBlock = false;
      defaultThinkingLevel = "medium";
      steeringMode = "all";
      followUpMode = "all";
      enableInstallTelemetry = false;
      packages = [
        "npm:pi-opencode-bridge@0.2.1"
        "npm:@llblab/pi-telegram@0.19.3"
        "npm:@ff-labs/pi-fff@0.9.6"
        "npm:pi-ask-user@0.11.2"
        "npm:@tintinweb/pi-tasks@0.7.1"
        "npm:@trevonistrevon/pi-loop@0.6.0"
        "npm:pi-web-access@0.13.0"
      ];
    };
  };

  home.file.".pi/agent/keybindings.json".text = builtins.toJSON {
    "tui.editor.cursorLeft" = ["left"];
    "tui.input.newLine" = ["shift+enter"];
    "app.models.clearAll" = ["ctrl+shift+x"];
  };

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
