{
  config,
  lib,
  pkgs,
  ...
}: let
  docroot = "/var/www/aldebaran";
  downloadDir = "/var/www/aldebaran-downloads";
  # The site repo is private, so the box authenticates over SSH with the key in
  # secrets/vps.yaml (`aldebaran-site-key`), registered on a GitHub account that
  # can read it. Without the key the update logs and skips instead of leaving
  # the site silently stale.
  repo = "git@github.com:AbuUqba/aldebaran-site.git";
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
    sops.secrets."aldebaran-site-key" = {};

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
        key=/run/secrets/aldebaran-site-key
        if [ ! -f "$key" ]; then
          echo "aldebaran-site: $key is missing (sops secret not installed) — leaving ${docroot} at $(cat "$state" 2>/dev/null || echo unknown)" >&2
          exit 0
        fi
        export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i $key -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
        head="$(${pkgs.git}/bin/git ls-remote ${repo} refs/heads/main 2>/dev/null | cut -f1 || true)"
        if [ -z "$head" ]; then
          echo "aldebaran-site: cannot read ${repo} with $key — leaving ${docroot} at $(cat "$state" 2>/dev/null || echo unknown)" >&2
          exit 0
        fi
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
      # The key comes from sops, which is materialised by this activation script.
      deps = ["setupSecrets"];
      text = ''
        ${update} || true
      '';
    };
  };
}