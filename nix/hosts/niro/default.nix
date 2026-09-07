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
        ...
      }: {
        imports = [
          ./hardware-configuration.nix
          ../../../cachix.nix
          (inputs.import-tree.filterNot (path:
            lib.hasSuffix "default.nix" path
            || lib.hasInfix "server/" (toString path)
          ) ../../../modules)

          inputs.paseo.nixosModules.paseo
          inputs.copyparty.nixosModules.default
          {
            nixpkgs.overlays = [
              inputs.copyparty.overlays.default
              (import ../../../overlays/fish-compat.nix)
            ];
          }

          inputs.sops-nix.nixosModules.sops

          inputs.niri.nixosModules.niri

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
              inherit inputs;
            };
          }
        ];

        boot.loader.grub.enable = true;
        boot.loader.grub.efiSupport = true;
        boot.loader.grub.device = "nodev";
        boot.loader.efi.canTouchEfiVariables = true;

        fileSystems."/mnt/media" = {
          device = "/dev/disk/by-uuid/1baa8f80-394b-42ac-ae3d-8afea4740ae4";
          fsType = "ext4";
          options = ["nofail"];
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
            hotspot-env = {
              path = "/var/lib/secrets/hotspot.env";
            };
            brave-api-key = {
              path = "${config.users.users.nir.home}/.pi/web-search.json";
              owner = "nir";
            };
          };
        };

        # Nvidia driver
        services.xserver.videoDrivers = ["nvidia"];
        boot.kernelParams = [
          "acpi_backlight=native"
          "nvidia.NVreg_RegistryDwords=EnableBrightnessControl=1"
          "nvidia_drm.fbdev=1"
          "nvidia-drm.modeset=1"
        ];
        hardware.graphics = {
          enable = true;
        };
        hardware.nvidia = {
          modesetting.enable = true;
          powerManagement.enable = true;
          powerManagement.finegrained = false;
          open = true;
          nvidiaSettings = true;
          package = config.boot.kernelPackages.nvidiaPackages.stable;
          prime = {
            sync.enable = true;
            intelBusId = "PCI:0:2:0";
            nvidiaBusId = "PCI:1:0:0";
          };
        };

        hardware.bluetooth.enable = true;
      };
      homeManager = {};
    };
  };
}
