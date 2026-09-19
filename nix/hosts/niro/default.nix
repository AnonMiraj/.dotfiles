{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.niro = self.lib.configs.nixos "x86_64-linux" "niro";

  flake.aspects = {aspects, ...}: {
    niro = {
      nixos = {
        config,
        lib,
        pkgs,
        inputs',
        self',
        ...
      }: {
        imports = [
          ./hardware-configuration.nix
          ../../../cachix.nix
          (inputs.import-tree.filterNot (
              path:
                lib.hasSuffix "default.nix" path
                || lib.hasInfix "server/" (toString path)
            )
            ../../../modules)

          inputs.paseo.nixosModules.paseo
          inputs.sops-nix.nixosModules.sops

          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.backupFileExtension = "HMBackup";
            home-manager.useUserPackages = true;
            home-manager.users.nir.imports = [
              inputs.vicinae.homeManagerModules.default
              ../../../users/nir/home.nix
            ];
            home-manager.extraSpecialArgs = {
              inherit inputs inputs' self';
            };
          }
        ];

        fileSystems."/mnt/media" = {
          device = "/dev/disk/by-uuid/1baa8f80-394b-42ac-ae3d-8afea4740ae4";
          fsType = "ext4";
          options = ["nofail"];
        };

        # Wi-Fi is the LAN uplink (ethernet being removed); both NICs are
        # still allowed so a rebuild during the transition keeps working.
        my.lan = {
          address = "192.168.1.6";
          interfaces = ["enp43s0" "wlp0s20f3"];
        };

        system.stateVersion = "25.11";

        sops = {
          gnupg.sshKeyPaths = [];
          defaultSopsFile = ../../../secrets/secrets.yaml;
          age.sshKeyPaths = ["${config.users.users.nir.home}/.ssh/id_ed25519"];
          secrets = {
            gatus-push-tokens = {
              path = "/var/lib/secrets/gatus-push.tokens";
              owner = "nir";
            };
            brave-api-key = {
              path = "${config.users.users.nir.home}/.pi/web-search.json";
              owner = "nir";
            };
          };
        };
      };
      homeManager = {};
    };
  };
}
