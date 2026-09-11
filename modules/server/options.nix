{
  lib,
  ...
}: let
  inherit (lib) types mkOption mkEnableOption;
in {
  options.my.server = {
    public = mkOption {
      description = "Master switch for the VPS public reverse-proxy site (Caddy + ACME).";
      type = types.bool;
      default = false;
    };

    bosla = {
      enable = mkEnableOption "bosla containers (frontend, api, typst-worker)";
    };
    "3x-ui" = {
      enable = mkEnableOption "3x-ui VPN/panel container";
    };
    frps = {
      enable = mkEnableOption "frp server (terminates home niro tunnels)";
    };
    gatus = {
      enable = mkEnableOption "gatus uptime monitor";
    };
    runner = {
      enable = mkEnableOption "GitHub self-hosted runner (Bosla-Ai)";
    };
    aldebaran = {
      enable = mkEnableOption "Aldebaran static site (aldebaran.moe + sciadv.almiraj.xyz)";
    };
  };

  # ── VPS public service registry (parallel to niro's modules/selfhost
  #    `my.services` LAN registry). Each entry becomes a Caddy vhost on the
  #    almiraj site; generation is gated per entry by the my.server.<x>.enable
  #    flags below, not by presence alone.
  options.my.publicServices = mkOption {
    description = "Public services exposed on the VPS (almiraj) via Caddy + Let's Encrypt.";
    type = types.attrsOf (types.submodule ({...}: {
      options = {
        domain = mkOption {
          type = types.str;
          description = "Full public FQDN, e.g. bosla.almiraj.xyz.";
        };
        port = mkOption {
          type = types.port;
          description = "Local upstream port on the VPS.";
        };
        proxyTarget = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Override upstream target (default: localhost:<port>).";
        };
        tls = mkOption {
          type = types.enum ["auto" "internal"];
          default = "auto";
          description = "auto = Let's Encrypt via Caddy; internal = not exposed publicly.";
        };
        checkPath = mkOption {
          type = types.str;
          default = "/";
          description = "Gatus health path on this service.";
        };
        group = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Gatus group label.";
        };
        openFirewall = mkOption {
          type = types.bool;
          default = true;
          description = "Whether this upstream port is reachable from the public interface.";
        };
      };
    }));
    default = {};
  };
}