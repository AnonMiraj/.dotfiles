{lib, ...}: let
  inherit (lib) types mkOption;
in {
  options.my = {
    services = mkOption {
      description = "Self-hosted service metadata for generating Caddy, Homepage, FRP, Gatus";
      type = types.attrsOf (types.submodule ({...}: {
        options = {
          port = mkOption {
            type = types.port;
            description = "Local port the service runs on";
          };
          domain = mkOption {
            type = types.str;
            description = "Subdomain under the lan.domain zone";
          };
          proxyTarget = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Override proxy target (default: localhost:<port>)";
          };
          homepage = {
            enable = mkOption {
              type = types.bool;
              default = true;
            };
            group = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Homepage group (Media / Dev / System)";
            };
            name = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            description = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            icon = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
          };
          gatus = {
            enable = mkOption {
              type = types.bool;
              default = true;
            };
            checkPath = mkOption {
              type = types.str;
              default = "/";
            };
            conditions = mkOption {
              type = types.listOf types.str;
              default = ["[STATUS] == 200"];
            };
          };
          frp = {
            enable = mkOption {
              type = types.bool;
              default = false;
            };
            remotePort = mkOption {
              type = types.nullOr types.port;
              default = null;
              description = "Override remote port (default: same as local port)";
            };
          };
        };
      }));
    };

    caddy = {
      extraVhosts = mkOption {
        description = "Extra Caddy vhosts not tied to a service (e.g. lab.almiraj.xyz -> homepage)";
        type = types.attrsOf (types.submodule {
          options = {
            proxyTarget = mkOption {
              type = types.str;
              description = "Reverse proxy target (e.g. localhost:8082)";
            };
          };
        });
        default = {
          "lab.almiraj.xyz".proxyTarget = "localhost:8082";
          "status.lab.almiraj.xyz".proxyTarget = "localhost:8099";
          "home.lab.almiraj.xyz".proxyTarget = "localhost:8082";
          "paseo.lab.almiraj.xyz".proxyTarget = "custom";
        };
      };
    };

    pushStatus = {
      vpsUrl = mkOption {
        type = types.str;
        default = "https://status.almiraj.xyz";
        description = "VPS Gatus URL for push-status";
      };
      tokenFile = mkOption {
        type = types.str;
        default = "/var/lib/secrets/gatus-push.tokens";
      };
      interval = mkOption {
        type = types.str;
        default = "2m";
        description = "Timer interval (e.g. 2m, 5m)";
      };
    };
    lan = {
      domain = mkOption {
        type = types.str;
        default = "lab.almiraj.xyz";
        description = "Internal split-brain DNS zone. Services get <name>.<lan.domain>; the same names resolve to my.lan.address on the LAN and are covered by the Let's Encrypt wildcard cert from modules/selfhost/acme.nix.";
      };
      address = mkOption {
        type = types.str;
        default = "192.168.1.6";
        description = "LAN IP of this host, advertised by dnsmasq for <lan.domain>.";
      };
      interface = mkOption {
        type = types.str;
        default = "enp43s0";
        description = "LAN interface dnsmasq binds to (in addition to lo).";
      };
      headscale = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Join the Headscale tailnet and advertise 192.168.1.0/24.";
        };
      };
    };
    vps = {
      address = mkOption {
        type = types.str;
        default = "152.53.81.54";
        description = "Public IPv4 of the almiraj VPS (frp server and backup target).";
      };
    };
  };
}
