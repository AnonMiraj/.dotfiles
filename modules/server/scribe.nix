{
  config,
  lib,
  ...
}: let
  root = "/var/lib/scribe-site";
  port = 8096;
in {
  # scribe.mko.software — Scribe's waitlist page (github.com/Mookhaled04/meet-scribe,
  # site/waitlist). A stock python image runs the repo's server.py, which serves the
  # page and keeps sign-ups in ${root}/data/scribe-site.sqlite3.
  #
  # Deploys need no rebuild: `python site/waitlist/deploy.py` (as dev) copies
  # index.html + server.py into ${root}/www, and stops the container when server.py
  # changed; Restart=always brings it back on the new code.
  config = lib.mkIf config.my.server.scribe.enable {
    systemd.tmpfiles.rules = [
      "d ${root} 0755 dev users -"
      "d ${root}/www 0755 dev users -"
      "d ${root}/data 0700 dev users -"
    ];

    virtualisation.oci-containers.containers.scribe-site = {
      image = "python:3.12-alpine";
      ports = ["127.0.0.1:${toString port}:8080"];
      volumes = [
        "${root}/www:/srv:ro"
        "${root}/data:/data"
      ];
      environment = {
        PORT = "8080";
        SCRIBE_SITE_DATA = "/data";
        PYTHONUNBUFFERED = "1";
      };
      # dev owns the data dir, so the container writes as dev (uid 1001, group users)
      user = "1001:100";
      cmd = ["sh" "-c" "test -f /srv/server.py && exec python3 /srv/server.py || exec python3 -m http.server 8080 -d /tmp"];
    };

    services.caddy.virtualHosts."scribe.mko.software" = {
      extraConfig = ''
        encode zstd gzip
        reverse_proxy 127.0.0.1:${toString port}
      '';
    };
  };
}
