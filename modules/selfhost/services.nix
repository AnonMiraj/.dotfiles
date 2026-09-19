{
  config,
  pkgs,
  ...
}: let
  domain = config.my.lan.domain;
in {
  systemd.services.glances = {
    description = "Glances system monitor";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      User = "nir";
      Group = "users";
      ExecStart = "${pkgs.glances.overridePythonAttrs (oldAttrs: {doCheck = false;})}/bin/glances -w --port 3001 --bind 127.0.0.1";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  services.paseo = {
    enable = true;
    user = "nir";
    group = "users";
    hostnames = ["paseo.${domain}" "paseo.almiraj.xyz"];
    listenAddress = "0.0.0.0";
    port = 6767;
    openFirewall = true;
    environment = {
      PASEO_CORS_ORIGINS = "https://paseo.${domain},http://localhost:6767,http://127.0.0.1:6767,http://paseo.almiraj.xyz";
    };
  };
  systemd.services.paseo.serviceConfig.ExecStartPre = [
    "${pkgs.coreutils}/bin/rm -f ${config.users.users.nir.home}/.paseo/paseo.pid"
  ];

  systemd.services.dufs = let
    dufs-nochecks = pkgs.dufs.overrideAttrs (_: {doCheck = false;});
  in {
    description = "Dufs file server";
    after = ["network.target" "mnt-media.mount"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      User = "nir";
      Group = "users";
      ExecStart = "${dufs-nochecks}/bin/dufs /mnt/media --port 3930 --bind 127.0.0.1";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
    group = "users";
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  services.bazarr = {
    enable = true;
    listenPort = 6768;
    openFirewall = true;
    group = "users";
  };

  systemd.services.fix-media-perms = {
    description = "Set ACLs on /mnt/media for shared service access";
    after = ["mnt-media.mount"];
    before = ["transmission-daemon.service" "sonarr.service" "bazarr.service" "aria2.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.acl}/bin/setfacl -R -m g:users:rwx /mnt/media";
      ExecStartPost = "${pkgs.acl}/bin/setfacl -R -m d:g:users:rwx /mnt/media";
      RemainAfterExit = true;
    };
  };
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    user = "nir";
    group = "users";
    home = "/var/lib/transmission";
    openFirewall = true;
    openRPCPort = true;
    settings = {
      download-dir = "/mnt/media";
      incomplete-dir = "/mnt/media/.incomplete";
      incomplete-dir-enabled = true;
      watch-dir = "/mnt/media/.watch";
      watch-dir-enabled = true;
      rpc-port = 9091;
      rpc-bind-address = "0.0.0.0";
      rpc-host-whitelist = "torr.${domain}";
      rpc-whitelist = "127.0.0.1,${config.my.lan.subnet}";
      peer-port = 51413;
      umask = 2;
    };
  };
  systemd.services.transmission.after = ["mnt-media.mount"];
  systemd.services.transmission.wants = ["mnt-media.mount"];

  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    allowedHosts = "${domain},home.${domain},localhost:8082";
    settings = {
      title = "niro";
      startUrl = "https://${domain}";
      background = {
        image = "https://images.unsplash.com/photo-1506905925346-21bda4d32df4";
        blur = "sm";
        opacity = 50;
      };
      theme = "dark";
      layout = [
        {
          "Media" = {
            style = "row";
            columns = 4;
          };
        }
        {
          "Dev" = {
            style = "row";
            columns = 4;
          };
        }
        {
          "System" = {
            style = "row";
            columns = 4;
          };
        }
        {
          "VPS" = {
            style = "row";
            columns = 4;
          };
        }
      ];
    };
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
      {
        datetime = {
          format = "%H:%M  %d/%m/%Y";
          timezone = "Africa/Cairo";
        };
      }
    ];
  };

  # Homepage does not watch the generated YAML, so restart when it changes.
  systemd.services.homepage-dashboard.restartTriggers = [
    config.environment.etc."homepage-dashboard/services.yaml".source
    config.environment.etc."homepage-dashboard/settings.yaml".source
  ];

  # Jellyfin
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "nir";
  };
  systemd.services.jellyfin.after = ["mnt-media.mount"];
  systemd.services.jellyfin.wants = ["mnt-media.mount"];

  # Sunshine (game streaming)
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  sops.secrets."aria2-rpc-secret" = {};

  # Aria2 Daemon
  services.aria2 = {
    enable = true;
    openPorts = true;
    rpcSecretFile = config.sops.secrets."aria2-rpc-secret".path;
    downloadDirPermission = "0775";
    serviceUMask = "0002";
    settings = {
      dir = "/mnt/media/downloads";
      max-connection-per-server = 16;
      min-split-size = "10M";
      split = 16;
      max-concurrent-downloads = 5;
      continue = true;
      enable-dht = true;
      rpc-allow-origin-all = true;
    };
  };
  systemd.services.aria2.after = ["mnt-media.mount"];
  systemd.services.aria2.wants = ["mnt-media.mount"];
  users.users.aria2.extraGroups = ["users"];
}
