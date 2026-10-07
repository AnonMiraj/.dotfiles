{
  config,
  lib,
  ...
}: let
  root = "/var/lib/scribe-cloud";
  port = 8790;
  domain = "cloud.scribe.mko.software";
in {
  # cloud.scribe.mko.software — Scribe Cloud (github.com/Mookhaled04/meet-scribe, cloud/):
  # Google sign-in, credits, Ask and the post-call notes job, with the provider gateway
  # beside it on the container's own localhost. Node standard library only.
  #
  # ${root}/app   code, copied by `python cloud/deploy.py` (as dev)
  # ${root}/data  SQLite, runtime.json, prompts/
  # ${root}/env   secrets the owner fills in: GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET,
  #               GATEWAY_TOKEN, KEY_SERVICE_TOKEN (same value) and provider keys
  #               (GEMINI_API_KEY, OPENAI_API_KEY, ...). Until GOOGLE_CLIENT_ID is set
  #               the container idles instead of crash-looping.
  config = lib.mkIf config.my.server.scribe.enable {
    systemd.tmpfiles.rules = [
      "d ${root} 0755 dev users -"
      "d ${root}/app 0755 dev users -"
      "d ${root}/data 0700 dev users -"
      "f ${root}/env 0600 dev users -"
    ];

    virtualisation.oci-containers.containers.scribe-cloud = {
      image = "node:22-alpine";
      ports = ["127.0.0.1:${toString port}:${toString port}"];
      volumes = [
        "${root}/app:/app:ro"
        "${root}/data:/data"
      ];
      environmentFiles = ["${root}/env"];
      environment = {
        HOST = "0.0.0.0";
        PORT = toString port;
        PUBLIC_URL = "https://${domain}";
        DB_PATH = "/data/scribe-cloud.sqlite";
        RUNTIME_FILE = "/data/runtime.json";
        PROMPTS_DIR = "/data/prompts";
        KEY_SERVICE_URL = "http://127.0.0.1:9000";
        GATEWAY_PORT = "9000";
      };
      user = "1001:100";
      cmd = [
        "sh"
        "-c"
        ''
          if [ ! -f /app/src/index.js ] || [ -z "$GOOGLE_CLIENT_ID" ]; then
            echo "scribe-cloud: waiting for code in /app and secrets in ${root}/env"; exec sleep infinity
          fi
          node /app/gateway/index.js & exec node /app/src/index.js
        ''
      ];
    };

    services.caddy.virtualHosts.${domain} = {
      extraConfig = ''
        encode zstd gzip
        # Ask streams SSE and the meeting job streams NDJSON: pass bytes through as they come
        reverse_proxy 127.0.0.1:${toString port} {
          flush_interval -1
        }
      '';
    };
  };
}
