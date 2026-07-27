{
  config,
  pkgs,
  ...
}: {
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
    hostnames = ["paseo.niro.lan" "paseo.almiraj.xyz"];
    listenAddress = "0.0.0.0";
    port = 6767;
    openFirewall = true;
    environment = {
      PASEO_CORS_ORIGINS = "https://paseo.niro.lan,http://localhost:6767,http://127.0.0.1:6767,http://paseo.almiraj.xyz";
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
    before = ["transmission-daemon.service" "sonarr.service" "bazarr.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.acl}/bin/setfacl -R -m g:users:rwx /mnt/media";
      ExecStartPost = "${pkgs.acl}/bin/setfacl -R -m d:g:users:rwx /mnt/media";
      RemainAfterExit = true;
    };
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers.kokoro = {
      image = "ghcr.io/remsky/kokoro-fastapi-gpu:latest";
      ports = ["8880:8880"];
      extraOptions = [
        "--device=nvidia.com/gpu=all"
      ];
    };
    containers.flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      ports = ["8191:8191"];
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
      rpc-host-whitelist = "torr.niro.lan,torr.nir.lan";
      rpc-whitelist = "127.0.0.1,192.168.1.*";
      peer-port = 51413;
      umask = 2;
    };
  };
  systemd.services.transmission.after = ["mnt-media.mount"];
  systemd.services.transmission.wants = ["mnt-media.mount"];

  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    allowedHosts = "niro.lan,home.niro.lan,localhost:8082";
    settings = {
      title = "niro";
      startUrl = "https://home.niro.lan";
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

  # Suwayomi (manga reader, disabled)
  services.suwayomi-server = {
    enable = false;
    openFirewall = true;
    settings = {
      server.port = 4567;
    };
  };
  systemd.services.suwayomi-server.after = ["mnt-media.mount"];
  systemd.services.suwayomi-server.wants = ["mnt-media.mount"];

}
