{
  config,
  lib,
  pkgs,
  ...
}: let
  docroot = "/var/www/aldebaran";
  downloadDir = "/var/www/aldebaran-downloads";
  repo = "https://github.com/AbuUqba/aldebaran-site.git";
  vhost = ''
    handle_path /download/* {
      root * ${downloadDir}
      file_server
    }
    handle {
      root * ${docroot}
      encode zstd gzip
      try_files {path} {path}/ /index.html
      file_server
    }
  '';
in {
  config = lib.mkIf config.my.server.aldebaran.enable {
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

    in {
      text = ''
        ${update} || true
      '';
    };
  };
}