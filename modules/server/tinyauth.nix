{
  config,
  lib,
  pkgs,
  ...
}: let
  # Tinyauth is a tiny forward-auth server: it shows a real HTML login page
  # (password-manager friendly, unlike the HTTP basic-auth dialog) and issues a
  # session cookie for `.almiraj.xyz`, so several vhosts can share one login.
  #
  # bcrypt hash of the password; rotate with:
  #   caddy hash-password --plaintext 'new-password'
  # Username: anonmiraj.
  authHash = "$2a$14$1MMeJDz.EJVEz3SgxSj44OPsIyL8Gu/Bf0bpYiA.ri4wfVaZaaP8S";
in {
  config = lib.mkIf config.my.server.tinyauth.enable {
    services.tinyauth = {
      enable = true;
      settings = {
        APPURL = "https://auth.almiraj.xyz";
        SERVER_ADDRESS = "127.0.0.1";
        # Comma-separated username:bcrypt-hash list.
        AUTH_USERS = "anonmiraj:${authHash}";
        AUTH_SECURECOOKIE = true;
        AUTH_TRUSTEDPROXIES = "127.0.0.1";
        AUTH_SESSIONEXPIRY = 604800; # 7 days
        UI_TITLE = "almiraj";
        SERVER_PORT = config.my.server.tinyauth.port;

        # qBittorrent WebUI: every path is gated, no PATH_ALLOW. qBittorrent
        # runs with LocalHostAuth=false (see modules/server/qbittorrent.nix),
        # so Caddy's loopback connection skips qBittorrent's own login page —
        # which would also leave /api/v2 wide open, so tinyauth has to cover
        # it. Machine clients authenticate with HTTP Basic (accepted by
        # default) or a tinyauth session cookie.
        APPS_QB_CONFIG_DOMAIN = "qb.almiraj.xyz";
        # GoatCounter: dashboard gated, tracking endpoints public.
        APPS_ANALYTICS_CONFIG_DOMAIN = "analytics.almiraj.xyz";
        APPS_ANALYTICS_PATH_ALLOW = "^/(count|api/v0/count)";
      };
    };

    # The login page itself (unprotected). Protected vhosts use
    # `forward_auth 127.0.0.1:3000 { uri /api/auth/caddy }`.
    services.caddy.virtualHosts."auth.almiraj.xyz" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.my.server.tinyauth.port}
      '';
    };
  };
}
