{
  config,
  lib,
  pkgs,
  ...
}: let
  docroot = "/var/www/aldebaran"; # deployed static site (the repo's `src/`)
  downloadDir = "/var/www/aldebaran-downloads"; # stable; not wiped by site re-clone
  repo = "https://github.com/AbuUqba/aldebaran-site.git";
  vhost = ''
    handle_path /download/* {
      root * ${downloadDir}
      file_server
    }
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
    # Patch downloads (SG-AR-v1.1.zip) are served from ${downloadDir}, a
    # separate tree that survives site re-clones (see the mirror step below).
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

    # Updates the site + mirrors the patch archive.
    #  - site: pull the repo's `src/` into ${docroot}; refresh only when the
    #    default branch moved (so we don't wipe the site on every boot).
    #  - mirror: the team drops the build at /home/admin/SG-AR-v1.1.zip; copy it
    #    into the stable download dir when newer. Keeps /download working after
    #    a site re-clone.
    system.activationScripts.aldebaran = let
      update = pkgs.writeShellScript "aldebaran-site-update" ''
        set -eu
        state=/var/lib/aldebaran/rev
        head="$(${pkgs.git}/bin/git ls-remote ${repo} refs/heads/main | cut -f1)"
        [ -n "$head" ] || exit 0
        if [ "$head" != "$(cat "$state" 2>/dev/null)" ]; then
          tmp=$(mktemp -d)
          trap 'rm -rf "$tmp"' EXIT
          ${pkgs.git}/bin/git clone -q --depth 1 ${repo} "$tmp/src"
          rm -rf ${docroot}
          mkdir -p ${docroot} /var/lib/aldebaran
          cp -a "$tmp/src/src/." ${docroot}/
          chown -R caddy:caddy ${docroot}
          echo "$head" > "$state"
          echo "aldebaran-site: updated ${docroot} to $head"
        fi
      '';
      mirror = pkgs.writeShellScript "aldebaran-download-mirror" ''
        set -eu
        src=/home/admin/SG-AR-v1.1.zip
        mkdir -p ${downloadDir}
        if [ -f "$src" ]; then
          if [ ! -f ${downloadDir}/SG-AR-v1.1.zip ] || [ "$src" -nt ${downloadDir}/SG-AR-v1.1.zip ]; then
            cp -a "$src" ${downloadDir}/SG-AR-v1.1.zip
          fi
          chown -R caddy:caddy ${downloadDir}
        fi
      '';
    in {
      text = ''
        ${update} || true
        ${mirror} || true
      '';
    };
  };
}