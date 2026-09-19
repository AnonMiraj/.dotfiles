# Docker containers for the desktop host.
{config, ...}: let
  kokoroPort = config.my.services.kokoro.port;
in {
  virtualisation.oci-containers = {
    backend = "docker";
    containers.kokoro = {
      # Pinned, not `:latest`: Docker keeps serving a cached tag until it is
      # told to re-pull, and the auto-unload below only exists from v0.8.2 on.
      # The cached `:latest` here was v0.2.4 from June 2025, so the model sat
      # in VRAM forever and the container never released it.
      image = "ghcr.io/remsky/kokoro-fastapi-gpu:v0.9.0";
      # Loopback only: Caddy reaches it, nothing else, so 8880 needs no
      # firewall hole.
      ports = ["127.0.0.1:${toString kokoroPort}:8880"];
      extraOptions = [
        "--device=nvidia.com/gpu=all"
      ];
      # Kokoro releases the model from VRAM itself after this many idle seconds
      # and reloads it lazily on the next inference request (torch.cuda
      # empty_cache included), so the container can stay up without holding the
      # ~1 GiB. The idle clock only counts inference, which is why the periodic
      # /health probes from Gatus and push-status are harmless: a probe neither
      # delays the unload nor brings the model back.
      environment = {
        MODEL_AUTO_UNLOAD_TIMEOUT_SECONDS = "900";
      };
    };
    containers.flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      ports = ["8191:8191"];
    };
  };
}
