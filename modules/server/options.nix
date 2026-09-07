{lib, ...}: {
  options.my.server = {
    mail = {
      enable = lib.mkEnableOption "mail stack (postfix + dovecot2 + rspamd + roundcube) — G6a";
      domains = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Mail domains served (e.g. icpczagazig.org).";
      };
    };
    bosla = {
      enable = lib.mkEnableOption "bosla containers (frontend, api, typst-worker)";
    };
    "3x-ui" = {
      enable = lib.mkEnableOption "3x-ui VPN/panel container";
    };
    frps = {
      enable = lib.mkEnableOption "frp server (terminates home niro tunnels)";
    };
    gatus = {
      enable = lib.mkEnableOption "gatus uptime monitor";
    };
    runner = {
      enable = lib.mkEnableOption "GitHub self-hosted runner (Bosla-Ai)";
    };
  };
}