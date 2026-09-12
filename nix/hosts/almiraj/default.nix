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

        my.server.aldebaran.enable = true;
        my.server.goatcounter.enable = true;

        system.stateVersion = "26.05";

        # Accept flake nixConfig (silences the "untrusted flake configuration"
        # warning on CI deploys). Granular trusted-substituters/trusted-public-keys
        # lists did not satisfy nix's flake-config trust check; root-only box,
        # so blanket-accept is fine.
        nix.settings.accept-flake-config = true;

        # Public-facing site (Caddy + ACME): serves almiraj.xyz blog + other vhosts
        # once their stacks are enabled.
        my.server.public = true;

        # Services enabled now (mail + github-runner deferred):
        # - frps: frp tunnel terminus for home (sops frps-toml)
        # - gatus: status page behind Caddy
        # - bosla: docker app stack (images must exist for the containers to start)
        # - 3x-ui: containerized VPN panel
        my.server.frps.enable = true;
        my.server.gatus.enable = true;
        my.server.bosla.enable = true;
        my.server.runner.enable = true;
        my.server."3x-ui".enable = true;
        my.server.cashflow.enable = true;
        my.server.qbittorrent = {
          enable = true;
          passwordHash = "@ByteArray(XNnG/RkDLPGSDx/bByHJXw==:5BmWht4lNccFVa9CCRNyuUz2dmyvjBc0AWZOUkP3c7crkQELhgDRUNRYhyQwPPVdWijz8f415FM9mL/iVkAUTQ==)";
        };



        networking.hostName = "almiraj";

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