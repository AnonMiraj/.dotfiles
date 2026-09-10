{
  config,
  lib,
  pkgs,
  ...
}: let
  runnerFor = name: repository: {
    enable = true;
    inherit name;
    url = "https://github.com/Bosla-Ai/${repository}";
    tokenFile = "/run/secrets/${name}-runner-token";
    tokenType = "registration";
    ephemeral = false;
    replace = true;
    user = "bosla-runner";
    group = "bosla-runner";
    # Keep the runner's native self-hosted, Linux and ARM64 labels.
    noDefaultLabels = false;
    extraLabels = ["almiraj" "bosla"];

    # Nixpkgs supplies patched native executables and Node 24, not upstream's
    # dynamically linked binaries. Existing JavaScript actions also use Node 24.
    nodeRuntimes = ["node24"];
    # Runner 2.336.0 still resolves its internal hashFiles process via node20,
    # while this nixpkgs package supplies only node24. Keep that internal path
    # usable without installing the retired Node 20 runtime.
    package = pkgs.github-runner.overrideAttrs (old: {
      postInstall =
        (old.postInstall or "")
        + ''
          test -x "$out/lib/externals/node24/bin/node"
          if [ ! -e "$out/lib/externals/node20" ]; then
            ln -s node24 "$out/lib/externals/node20"
          fi
        '';
    });
    extraEnvironment.FORCE_JAVASCRIPT_ACTIONS_TO_NODE24 = "true";
    extraPackages = with pkgs; [
      bashInteractive
      coreutils
      git
      docker
      docker-buildx
      nodejs_24
      curl
      jq
      gnutar
      gzip
      unzip
      python3
    ];

    serviceOverrides = {
      # Docker and the setuid sudo wrapper must see real host users/groups.
      NoNewPrivileges = false;
      PrivateUsers = false;
      RestrictSUIDSGID = false;
      SupplementaryGroups = ["docker"];

      # Preserve a read-only host filesystem. The deployment helper uses the
      # Docker/systemd sockets, one lock file, and root's registry credentials.
      ProtectSystem = "strict";
      ReadWritePaths = ["/run/lock"];
      ProtectHome = "tmpfs";
      BindReadOnlyPaths = ["-/root/.docker"];

      # Sudo needs these capabilities to establish its root identity. The
      # helper-only sudo rule is supplied by the Bosla deployment module.
      CapabilityBoundingSet = lib.mkForce [
        "CAP_SETUID"
        "CAP_SETGID"
        "CAP_AUDIT_WRITE"
      ];
      # Keep the module's syscall restrictions except capset: systemd needs it
      # to drop setup capabilities without forcing NoNewPrivileges on, and
      # sudo needs it for its own privilege changes.
      SystemCallFilter = lib.mkForce [
        "~@clock"
        "~@cpu-emulation"
        "~@module"
        "~@mount"
        "~@obsolete"
        "~@raw-io"
        "~@reboot"
        "~setdomainname"
        "~sethostname"
      ];
    };
  };
  runnerNames = ["bosla-api" "bosla-frontend" "bosla-pipeline"];
in {
  config = lib.mkIf config.my.server.runner.enable {
    # These are deployment runners for trusted main-branch workflows only.
    # Labels select jobs; they do not isolate untrusted PR code. Docker access
    # is equivalent to host root, so do not assign PR/fork jobs to these runners.
    users.groups.bosla-runner = {};
    users.users.bosla-runner = {
      isSystemUser = true;
      group = "bosla-runner";
      extraGroups = ["docker"];
    };

    # Add both keys to encrypted secrets/vps.yaml before enabling the host flag.
    # Registration tokens expire after one hour. Existing credentials persist
    # across restarts, but changes to registration settings or secret contents
    # require fresh tokens; renew them immediately before applying such changes.
    sops.secrets = lib.genAttrs (map (name: "${name}-runner-token") runnerNames) (name: {
      path = "/run/secrets/${name}";
      mode = "0400";
      restartUnits = ["github-runner-${lib.removeSuffix "-runner-token" name}.service"];
    });

    services.github-runners = {
      bosla-api = runnerFor "bosla-api" "API";
      bosla-frontend = runnerFor "bosla-frontend" "Frontend";
      bosla-pipeline = runnerFor "bosla-pipeline" "Pipeline";
    };

    systemd.services = lib.genAttrs (map (name: "github-runner-${name}") runnerNames) (_: {
      after = ["docker.service"];
      wants = ["docker.service"];
      # Pick the NixOS setuid wrapper, not an unprivileged sudo store binary.
      path = lib.mkBefore ["/run/wrappers"];
    });
  };
}
