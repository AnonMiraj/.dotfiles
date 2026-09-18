# Docker containers for the desktop host.
#
# `autoStart` defaults to true and the module already sets Restart =
# "on-failure", so both containers come back on boot and after a crash
# without any extra options here.
{...}: {
  virtualisation.oci-containers = {
    backend = "docker";
    containers.kokoro = {
      image = "ghcr.io/remsky/kokoro-fastapi-gpu:latest";
      ports = ["8880:8880"];
      extraOptions = [
        "--device=nvidia.com/gpu=all"
      ];
    };
    containers.flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      ports = ["8191:8191"];
    };
  };
}
