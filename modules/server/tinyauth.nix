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

        # Per-app rules. Only requests whose Host matches CONFIG_DOMAIN are
        # governed by these; everything else still needs a login. PATH_ALLOW is
        # a regex of paths that skip auth entirely (machine clients).
        # qBittorrent WebUI: dashboard gated, its own API open (the *arr
        # download clients authenticate against qBittorrent itself).
        APPS_QB_CONFIG_DOMAIN = "qb.almiraj.xyz";
        APPS_QB_PATH_ALLOW = "^/api/v2";
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
