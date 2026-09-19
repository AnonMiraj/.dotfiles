{lib, ...}: let
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
    cashflow = {
      enable = mkEnableOption "Cash Flow game server (cashflow.almiraj.xyz)";
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
    headscale = {
      enable = mkEnableOption "Headscale control server for Tailscale clients";
    };
    runner = {
      enable = mkEnableOption "GitHub self-hosted runner (Bosla-Ai)";
    };
    aldebaran = {
      enable = mkEnableOption "Aldebaran static site (aldebaran.moe + sciadv.almiraj.xyz)";
    };
    goatcounter = {
      enable = mkEnableOption "GoatCounter analytics (analytics.almiraj.xyz)";
    };
    gsoc = {
      enable = mkEnableOption "GSoC organizations mirror (gsoc.almiraj.xyz → www.gsocorganizations.dev)";
    };
    stats = {
      enable = mkEnableOption "GoAccess access-log reports (stats.almiraj.xyz)";
    };
    tinyauth = {
      enable = mkEnableOption "Tinyauth forward-auth login server (auth.almiraj.xyz)";
      port = mkOption {
        type = types.port;
        default = 3000;
        description = "Loopback port tinyauth listens on; used for forward_auth upstreams.";
      };
    };
  };
}
