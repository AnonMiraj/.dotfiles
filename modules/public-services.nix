# Shared registry of services exposed publicly on the VPS.
#
# Lives outside `modules/server/` so both hosts can read it: `almiraj` uses it
# to generate Caddy vhosts + Gatus checks, `niro` uses it to list the same
# domains on the Homepage dashboard at https://lab.almiraj.xyz.
{lib, ...}: let
  inherit (lib) types mkOption;
in {
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
        stack = mkOption {
          type = types.str;
          description = "my.server.<stack>.enable flag that gates this public service.";
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
        auth = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Gate this vhost behind tinyauth (forward_auth). Path exceptions are
            declared per app in modules/server/tinyauth.nix.
          '';
        };
      };
    }));
    default = {};
  };

  options.my.publicDashboard = mkOption {
    description = "Curated public domains shown on the Homepage dashboard.";
    type = types.attrsOf (types.submodule ({...}: {
      options = {
        name = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
        domain = mkOption {
          type = types.str;
        };
        href = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Override the full URL (e.g. a panel path).";
        };
        icon = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
        description = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
      };
    }));
    default = {};
  };

  config.my.publicServices = {
    "bosla-api" = {
      domain = "bosla.almiraj.xyz";
      port = 5280;
      proxyTarget = "localhost:5280";
      stack = "bosla";
      checkPath = "/";
      group = "bosla";
    };
    "bosla-frontend" = {
      domain = "front.bosla.almiraj.xyz";
      port = 3001;
      stack = "bosla";
      checkPath = "/";
      group = "bosla";
    };
    "bosla-me" = {
      domain = "bosla.me";
      port = 3001;
      stack = "bosla";
      checkPath = "/";
      group = "bosla";
    };

    "3xui-panel" = {
      domain = "vpn.almiraj.xyz";
      port = 2053;
      stack = "3x-ui";
      checkPath = "/";
      group = "vpn";
    };

    status = {
      domain = "status.almiraj.xyz";
      port = 8099;
      stack = "gatus";
      checkPath = "/";
      group = "system";
    };

    analytics = {
      domain = "analytics.almiraj.xyz";
      port = 8050;
      stack = "goatcounter";
      checkPath = "/status";
      group = "system";
      auth = true;
    };
  };

  # Curated for the Homepage dashboard: no bosla services, everything else
  # public on the VPS.
  config.my.publicDashboard = {
    "almiraj-xyz" = {
      name = "almiraj.xyz";
      domain = "almiraj.xyz";
      icon = "https://almiraj.xyz/images/favicon-32x32.png";
    };
    "aldebaran-moe" = {
      name = "Aldebaran";
      domain = "aldebaran.moe";
      icon = "https://aldebaran.moe/img/icons/favicon-32.png";
    };
    "sciadv" = {
      name = "SciADV";
      domain = "sciadv.almiraj.xyz";
      icon = "https://sciadv.almiraj.xyz/img/icons/favicon-32.png";
    };
    "gsoc" = {
      name = "GSoC Mirror";
      domain = "gsoc.almiraj.xyz";
      icon = "https://gsoc.almiraj.xyz/favicon-32x32.png";
    };
    "stats" = {
      name = "Stats";
      domain = "stats.almiraj.xyz";
      icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/goaccess.png";
    };
    "analytics" = {
      name = "Analytics";
      domain = "analytics.almiraj.xyz";
      icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/google-analytics.png";
    };
    "auth" = {
      name = "Auth";
      domain = "auth.almiraj.xyz";
      icon = "https://auth.almiraj.xyz/favicon.ico";
    };
    "cashflow" = {
      name = "Cash Flow";
      domain = "cashflow.almiraj.xyz";
      icon = "https://cashflow.almiraj.xyz/favicon.svg";
    };
    "qbittorrent" = {
      name = "qBittorrent";
      domain = "qb.almiraj.xyz";
      icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/qbittorrent.png";
    };
    "downloads" = {
      name = "Downloads";
      domain = "dl.almiraj.xyz";
      icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/jdownloader.png";
    };
    "status" = {
      name = "Status";
      domain = "status.almiraj.xyz";
      icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/gatus.png";
    };
    "vpn" = {
      name = "VPN Panel";
      domain = "vpn.almiraj.xyz";
      href = "https://vpn.almiraj.xyz/xui_oV36PZWw/";
      icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/wireguard.png";
    };
    "headscale" = {
      name = "Headscale";
      domain = "headscale.almiraj.xyz";
      icon = "https://headscale.almiraj.xyz/favicon.ico";
    };
    "aria" = {
      name = "Aria2";
      domain = "aria.almiraj.xyz";
      icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/ariang.png";
    };
  };
}
