{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.almiraj = self.lib.configs.nixos "aarch64-linux" "almiraj";

  flake.aspects = {
    aspects,
    ...
  }: {
    almiraj = {
      nixos = {
        config,
        lib,
        pkgs,
        ...
      }: {
        imports = [
          ../../../cachix.nix
          ../../../modules/base.nix
          (inputs.import-tree.filterNot (path: lib.hasSuffix "default.nix" path) ../../../modules/server)
          inputs.sops-nix.nixosModules.sops
        ];

        system.stateVersion = "26.05";

        networking.hostName = "almiraj";

        # netcup networking is static (no DHCP). Addresses from SCP are filled
        # in during Phase 3; the ZFS root + boot loader come with the disko
        # config and its generated hardware-configuration.nix.
        networking.useDHCP = false;
        networking.networkmanager.enable = false;

        sops = {
          gnupg.sshKeyPaths = [];
          defaultSopsFile = ../../../secrets/vps.yaml;
          age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
          secrets = {};
        };
      };
      homeManager = {};
    };
  };
}