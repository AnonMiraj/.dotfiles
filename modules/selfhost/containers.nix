# Docker containers for the desktop host, plus Kokoro's wake-on-request plumbing.
{
  config,
  pkgs,
  ...
}: let
  kokoroPort = config.my.services.kokoro.port;

  # Where the container publishes itself. Deliberately not kokoroPort: the wake
  # socket owns that, so it can intercept the first connection.
  kokoroBackendPort = 18880;

  # The socket starts this service on the first connection, at which point the
  # container is still booting. Wait for it to answer before handing the
  # connection to the proxy, otherwise the first request after idle is dropped.
  waitForKokoro = pkgs.writeShellScript "kokoro-wait" ''
    set -euo pipefail
    for _ in $(seq 1 120); do
      if ${pkgs.curl}/bin/curl -s -o /dev/null --max-time 2 \
        "http://127.0.0.1:${toString kokoroBackendPort}/health"; then
        exit 0
      fi
      sleep 1
    done
    echo "kokoro: no response on ${toString kokoroBackendPort} after 120s" >&2
    exit 1
  '';
in {
  virtualisation.oci-containers = {
    backend = "docker";
    containers.kokoro = {
      image = "ghcr.io/remsky/kokoro-fastapi-gpu:latest";
      # Loopback only: Caddy and frpc reach it through the wake socket, which
      # listens on the service port.
      ports = ["127.0.0.1:${toString kokoroBackendPort}:8880"];
      extraOptions = [
        "--device=nvidia.com/gpu=all"
      ];
      # The point of the socket below: hold no VRAM until something asks.
      autoStart = false;
    };
    containers.flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      ports = ["8191:8191"];
    };
  };

  # ── Kokoro wake-on-request ──────────────────────────────────────
  #
  # This only works because nothing polls Kokoro any more: its metadata entry
  # sets gatus.enable = false, which also stops push-status probing it. A health
  # check every 30s would restart the container before it ever went idle.
  systemd.sockets.kokoro-wake = {
    description = "Wake socket for the Kokoro TTS container";
    wantedBy = ["sockets.target"];
    socketConfig = {
      ListenStream = "127.0.0.1:${toString kokoroPort}";
      Service = "kokoro-wake.service";
      # Not Accept=yes: the proxy needs the listening socket handed over so it
      # can keep serving reconnects, and systemd keeps it open while the
      # service is stopped, so the next connection wakes it again.
      Accept = false;
    };
  };

  systemd.services.kokoro-wake = {
    description = "Start Kokoro on demand and proxy the wake socket to it";
    requires = ["docker-kokoro.service"];
    after = ["docker-kokoro.service"];
    serviceConfig = {
      ExecStartPre = waitForKokoro;
      ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd --exit-idle-time=15min 127.0.0.1:${toString kokoroBackendPort}";
      # Runs when the proxy exits after the idle timeout, and also if it fails
      # to start, so the container never lingers holding VRAM.
      ExecStopPost = "${config.systemd.package}/bin/systemctl --no-block stop docker-kokoro.service";
      # Loading the TTS model on a cold start can take a while.
      TimeoutStartSec = "180s";
    };
  };
}
