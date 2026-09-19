{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.almiraj = self.lib.configs.nixos "aarch64-linux" "almiraj";

  flake.aspects = {aspects, ...}: {
    almiraj = {
      nixos = {
        config,
        lib,
        pkgs,
        ...
      }: {
        imports = [
          ../../../cachix.nix
          ../../../modules/shared.nix
          ../../../modules/public-services.nix
          (inputs.import-tree.filterNot (path: lib.hasSuffix "default.nix" path) ../../../modules/server)
          inputs.sops-nix.nixosModules.sops
          inputs.disko.nixosModules.disko
        ];

        my.server.aldebaran.enable = true;
        my.server.goatcounter.enable = true;
        my.server.gsoc.enable = true;
        my.server.stats = {
          enable = true;
          anonymizeIp = false; # report sits behind tinyauth
        };
        my.server.tinyauth.enable = true;

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
        # - gatus: status page behind Caddy
        # - bosla: docker app stack (images must exist for the containers to start)
        # - 3x-ui: containerized VPN panel
        # - stats: GoAccess HTML reports built from the Caddy access logs
        # - cashflow: nix-built game server behind Caddy (see modules/server/cashflow.nix)
        my.server.gatus.enable = true;
        my.server.bosla.enable = true;
        my.server.runner.enable = true;
        my.server."3x-ui".enable = true;
        my.server.headscale.enable = true;
        my.server.cashflow.enable = true;
        my.server.qbittorrent = {
          enable = true;
          passwordHash = "@ByteArray(XNnG/RkDLPGSDx/bByHJXw==:5BmWht4lNccFVa9CCRNyuUz2dmyvjBc0AWZOUkP3c7crkQELhgDRUNRYhyQwPPVdWijz8f415FM9mL/iVkAUTQ==)";
        };
        my.server.downloads.enable = true;
        my.server.aria2.enable = true;

        networking.hostName = "almiraj";

        networking.usePredictableInterfaceNames = false;
        networking.useDHCP = false;
        networking.networkmanager.enable = false;
        networking.nameservers = ["1.1.1.1" "9.9.9.9"];

        networking.interfaces.eth0 = {
          ipv4.addresses = [
            {
              address = "152.53.81.54";
              prefixLength = 22;
            }
          ];
          ipv6.addresses = [
            {
              address = "2a0a:4cc0:2000:38bf::";
              prefixLength = 64;
            }
          ];
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
          secrets = {
            # Read-only automation key for the private cashflow flake input.
            # The CI deploy runs `nixos-rebuild --flake github:...#almiraj` as
            # root on this box, so Nix has to fetch that input over ssh while
            # evaluating. Kept root-only, out of the world-readable store.
            cashflow-deploy-key = {
              path = "/run/secrets/cashflow-deploy-key";
              mode = "0400";
            };
          };
        };

        # Public github.com host key, for root's ssh while fetching that input.
        programs.ssh.knownHosts.github = {
          hostNames = ["github.com"];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
        };

        # Put the key where root's ssh (and libgit2) look for it, and copy the
        # known-hosts file into root's home too, since the system file is not
        # always consulted by the fetcher.
        systemd.services.cashflow-deploy-key = {
          description = "Install the read-only key for the private cashflow flake input";
          after = ["sops-nix.service"];
          wants = ["sops-nix.service"];
          wantedBy = ["multi-user.target"];
          path = [pkgs.coreutils];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            install -d -m 0700 /root/.ssh
            install -m 0600 ${config.sops.secrets.cashflow-deploy-key.path} /root/.ssh/id_ed25519
            printf 'Host github.com\n  IdentityFile /root/.ssh/id_ed25519\n  IdentitiesOnly yes\n' > /root/.ssh/config
            chmod 0600 /root/.ssh/config
            install -m 0600 /etc/ssh/ssh_known_hosts /root/.ssh/known_hosts
          '';
        };
      };
      homeManager = {};
    };
  };
}
