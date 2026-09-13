{
  config,
  lib,
  ...
}: {
  # gsoc.almiraj.xyz — read-only reverse proxy in front of
  # www.gsocorganizations.dev (Netlify-hosted Gatsby site). Egypt blocks
  # Netlify, so this serves the same site through the VPS.
  config = lib.mkIf config.my.server.gsoc.enable {
    services.caddy.virtualHosts."gsoc.almiraj.xyz" = {
      extraConfig = ''
        reverse_proxy https://www.gsocorganizations.dev {
          header_up Host www.gsocorganizations.dev
          header_down Location "^https?://(www\.)?gsocorganizations\.dev" ""
        }
      '';
    };
  };
}
