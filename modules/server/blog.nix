{
  config,
  lib,
  ...
}: let
  docroot = "/var/www/almiraj";
in {
  config = lib.mkIf config.my.server.public {
    # almiraj.xyz — Hugo blog (static site deployed to ${docroot}).
    # Serve at the apex + redirect www. Caddy auto-provisions LE TLS on first hit.
    services.caddy.virtualHosts = {
      "almiraj.xyz" = {
        extraConfig = ''
          root * ${docroot}
          encode zstd gzip
          try_files {path} {path}/ /index.html
          file_server
        '';
      };
      "www.almiraj.xyz" = {
        extraConfig = ''
          redir https://almiraj.xyz{uri} permanent
        '';
      };
    };
  };
}