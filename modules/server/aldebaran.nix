{
  config,
  lib,
  pkgs,
  ...
}: let
  docroot = "/var/www/aldebaran"; # deployed static site (the repo's `src/`)
  repo = "https://github.com/AbuUqba/aldebaran-site.git";
  vhost = ''
    root * ${docroot}
    encode zstd gzip
    try_files {path} {path}/ /index.html
    file_server
  '';
in {
  config = lib.mkIf config.my.server.aldebaran.enable {
    # Aldebaran — static Arabic site, no build step. The repo's `src/` directory
    # is what deploys. Served read-only on two hostnames:
    #   aldebaran.moe        (direct DNS → this box)
    #   sciadv.almiraj.xyz   (proxied through Cloudflare with almiraj.xyz)
    services.caddy.virtualHosts = {
      "aldebaran.moe" = {
        extraConfig = vhost;
      };
      "www.aldebaran.moe" = {
        extraConfig = ''
          redir https://aldebaran.moe{uri} permanent
        '';
      };
      "sciadv.almiraj.xyz" = {
        extraConfig = vhost;
      };
    };

    # Pull the repo's `src/` into ${docroot}. On every nixos-rebuild (and boot)
    # the activation script refreshes it only when the default branch moved.
    system.activationScripts.aldebaran-site = let
      update = pkgs.writeShellScript "aldebaran-site-update" ''
        set -eu
        state=/var/lib/aldebaran/rev
        head="$(${pkgs.git}/bin/git ls-remote ${repo} refs/heads/main | cut -f1)"
        [ -n "$head" ] || exit 0
        [ "$head" = "$(cat "$state" 2>/dev/null)" ] && exit 0
        tmp=$(mktemp -d)
        trap 'rm -rf "$tmp"' EXIT
        ${pkgs.git}/bin/git clone -q --depth 1 ${repo} "$tmp/src"
        rm -rf ${docroot}
        mkdir -p ${docroot} /var/lib/aldebaran
        cp -a "$tmp/src/src/." ${docroot}/
        chown -R caddy:caddy ${docroot}
        echo "$head" > "$state"
        echo "aldebaran-site: updated ${docroot} to $head"
      '';
    in {
      text = ''
        ${update} || true
      '';
    };
  };
}