{
  config,
  lib,
  pkgs,
  ...
}: let
  docroot = "/var/www/almiraj"; # Hugo output served by Caddy
  repo = "https://github.com/AnonMiraj/almiraj-blog";
in {
  config = lib.mkIf config.my.server.public {
    # almiraj.xyz — Hugo blog served from ${docroot}.
    #
    # The site is built in the almiraj-blog repo's GitHub Actions workflow and
    # published to its `gh-pages` branch. On every nixos-rebuild (and boot) the
    # activation script below checks gh-pages' latest commit and refreshes
    # ${docroot} only when it changed.

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

    system.activationScripts.almiraj-blog = let
      update = pkgs.writeShellScript "almiraj-blog-update" ''
        set -eu
        state=/var/lib/almiraj-blog/rev
        head="$(${pkgs.git}/bin/git ls-remote ${repo} refs/heads/gh-pages | cut -f1)"
        [ -n "$head" ] || exit 0
        [ "$head" = "$(cat "$state" 2>/dev/null)" ] && exit 0
        tmp=$(mktemp -d)
        trap 'rm -rf "$tmp"' EXIT
        ${pkgs.git}/bin/git clone -q --depth 1 --branch gh-pages ${repo} "$tmp/src"
        rm -rf ${docroot}
        mkdir -p ${docroot} /var/lib/almiraj-blog
        cp -a "$tmp/src/." ${docroot}/
        chown -R caddy:caddy ${docroot}
        echo "$head" > "$state"
        echo "almiraj-blog: updated ${docroot} to $head"
      '';
    in {
      text = ''
        ${update} || true
      '';
    };
  };
}
