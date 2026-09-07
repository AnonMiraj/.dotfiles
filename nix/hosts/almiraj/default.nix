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
          inputs.disko.nixosModules.disko
        ];

        system.stateVersion = "26.05";

        # Public-facing site (Caddy + ACME): serves almiraj.xyz blog + other vhosts
        # once their stacks are enabled.
        my.server.public = true;


        networking.hostName = "almiraj";

        # netcup networking is STATIC (no DHCP). Classic approach, proven on
        # netcup: predictable interface names OFF so the NIC is `eth0` (the same
        # name Grml uses on this box), then standard networking.interfaces.
        networking.usePredictableInterfaceNames = false;
        networking.useDHCP = false;
        networking.networkmanager.enable = false;
        networking.nameservers = ["1.1.1.1" "9.9.9.9"];

        networking.interfaces.eth0 = {
          ipv4.addresses = [{
            address = "152.53.81.54";
            prefixLength = 22;
          }];
          ipv6.addresses = [{
            address = "2a0a:4cc0:2000:38bf::";
            prefixLength = 64;
          }];
        };
        networking.defaultGateway = "152.53.80.1";
        networking.defaultGateway6 = {
          address = "fe80::1";
          interface = "eth0";
        };

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