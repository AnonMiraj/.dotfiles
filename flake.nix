# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      (inputs.import-tree.filterNot (
        path:
        builtins.any (suffix: inputs.nixpkgs.lib.hasSuffix suffix path) [
          "npins/default.nix"
          "hardware-configuration.nix"
        ]
      ))
        ./nix
    );

  nixConfig = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://cache.nixos-cuda.org"
      "https://catppuccin.cachix.org"
      "https://cache.lix.systems"
      "https://niri.cachix.org"
      "https://yazi.cachix.org"
      "https://vicinae.cachix.org"
      "https://nvf.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "nvf.cachix.org-1:7D+YxLvO0ZtsY+MKZwq9JngtftxPtk+WXoHI5q7uO0Y="
    ];
  };

  inputs = {
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    awww = {
      url = "git+https://codeberg.org/LGFae/awww.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    copyparty = {
      url = "github:9001/copyparty/hovudstraum";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fconv-nvim = {
      url = "github:AnonMiraj/fconv.nvim";
      flake = false;
    };
    flake-aspects.url = "github:vic/flake-aspects";
    flake-file.url = "github:vic/flake-file";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flint = {
      url = "github:NotAShelf/flint";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
    jellyfin-vicinae = {
      url = "github:AnonMiraj/Jellyfin-vicinae";
      flake = false;
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    make-shell = {
      url = "github:nicknovitski/make-shell";
      inputs.flake-compat.follows = "";
    };
    niri = {
      url = "github:epireyn/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-zoom = {
      url = "github:AnonMiraj/niri-zoom/add-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    noctalia = {
      url = "git+https://github.com/noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    paseo = {
      url = "github:getpaseo/paseo/c5442ef0a24af06d32b35a21f7ac8d257917f8dd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    skills-flake = {
      url = "github:bitbloxhub/skills-flake";
      inputs = {
        flake-file.follows = "flake-file";
        flake-parts.follows = "flake-parts";
        flint.follows = "flint";
        import-tree.follows = "import-tree";
        make-shell.follows = "make-shell";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stasis = {
      url = "github:saltnpepper97/stasis";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    subminer = {
      url = "github:AnonMiraj/SubMiner/niri_back";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vicinae-extensions = {
      url = "git+https://github.com/vicinaehq/extensions.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
