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
            description = "Subdomain under niro.lan";
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
      certDir = mkOption {
        type = types.str;
        default = "/var/lib/caddy/certs";
        description = "Directory containing TLS cert files";
      };
      certFile = mkOption {
        type = types.str;
        default = "niro-lan.pem";
      };
      keyFile = mkOption {
        type = types.str;
        default = "niro-lan-key.pem";
      };
      extraVhosts = mkOption {
        description = "Extra Caddy vhosts not tied to a service (e.g. niro.lan → homepage)";
        type = types.attrsOf (types.submodule {
          options = {
            proxyTarget = mkOption {
              type = types.str;
              description = "Reverse proxy target (e.g. localhost:8082)";
            };
            serverAliases = mkOption {
              type = types.listOf types.str;
              default = [];
            };
          };
        });
        default = {
          "niro.lan".proxyTarget = "localhost:8082";
          "status.niro.lan".proxyTarget = "localhost:8099";
          "home.niro.lan" = {
            proxyTarget = "localhost:8082";
            serverAliases = ["*.home.niro.lan"];
          };
          "paseo.niro.lan" = {
            proxyTarget = "custom";
            serverAliases = ["*.paseo.niro.lan"];
          };
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
  };
}
