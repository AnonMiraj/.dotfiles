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

        networking.hostName = "almiraj";

        # netcup networking is STATIC (no DHCP; native no SLAAC assist).
        # Configured via systemd-networkd matched on the NIC MAC so we don't
        # depend on the virtio interface name (ens3/enp1s0/eth0).
        networking = {
          useDHCP = false;
          useNetworkd = true;
          networkmanager.enable = false;
          nameservers = ["1.1.1.1" "9.9.9.9"];
        };

        systemd.network.networks."10-uplink" = {
          matchConfig.MACAddress = "66:cb:80:e8:72:ab";
          address = [
            "152.53.81.54/22"
            "2a0a:4cc0:2000:38bf::/64"
          ];
          routes = [
            {
              Destination = "default";
              Gateway = "152.53.80.1";
            }
            {
              Destination = "default";
              Gateway = "fe80::1";
              GatewayOnLink = true;
            }
          ];
          networkConfig.IPv6AcceptRA = false;
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