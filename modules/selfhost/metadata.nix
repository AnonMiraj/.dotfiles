# Service metadata template:
# servicename = {
#   port = 1234;                        # required — local port
#   domain = "sub";                     # required — subdomain.lab.almiraj.xyz
#   proxyTarget = "localhost:1234";     # optional — override proxy target
#   homepage.group = "Media";           # optional — Media / Dev / System
#   homepage.name = "My Service";       # optional — display name (default: capitalized attr name)
#   homepage.description = "...";       # optional
#   homepage.icon = "https://...";      # optional — icon URL
#   gatus.enable = true;                # optional — default true
#   gatus.checkPath = "/health";        # optional — default "/"
# };
{...}: {
  my.services = {
    ssh = {
      port = 22;
      domain = "ssh";
      homepage.enable = false;
      gatus.enable = false;
    };
    jellyfin = {
      port = 8096;
      domain = "fin";
      homepage.group = "Media";
      homepage.icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/jellyfin.png";
    };
    paseo = {
      port = 6767;
      domain = "paseo";
      homepage.group = "Dev";
      homepage.icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/code-server.png";
      homepage.description = "AI coding agent orchestration";
      gatus.checkPath = "/api/health";
    };
    transmission = {
      port = 9091;
      domain = "torr";
      homepage.group = "Media";
      homepage.icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/transmission.png";
    };
    sonarr = {
      port = 8989;
      domain = "sonarr";
      homepage.group = "Media";
      homepage.icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/sonarr.png";
      homepage.description = "TV show PVR";
    };
    flaresolverr = {
      port = 8191;
      domain = "flare";
      homepage.group = "Media";
      homepage.name = "FlareSolverr";
      homepage.icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/flaresolverr.png";
      homepage.description = "Cloudflare bypass proxy";
      gatus.checkPath = "/";
    };
    prowlarr = {
      port = 9696;
      domain = "prowlarr";
      homepage.group = "Media";
      homepage.icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/prowlarr.png";
      homepage.description = "Indexer manager";
    };
    bazarr = {
      port = 6768;
      domain = "subs";
      homepage.group = "Media";
      homepage.icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/bazarr.png";
      homepage.description = "Subtitle manager";
    };
    dufs = {
      port = 3930;
      domain = "files";
      homepage.group = "Media";
      homepage.name = "File Server";
      homepage.icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/dufs.png";
      homepage.description = "File browser";
    };
    glances = {
      port = 3001;
      domain = "sys";
      homepage.group = "System";
      homepage.name = "System Monitor";
      homepage.icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/glances.png";
      homepage.description = "System monitor";
    };
    kokoro = {
      port = 8880;
      domain = "kokoro";
      homepage.group = "Dev";
      homepage.name = "Kokoro TTS";
      homepage.icon = "https://cdn.jsdelivr.net/npm/@mdi/svg@latest/svg/microphone.svg";
      homepage.description = "TTS engine";
      # VRAM is freed by the container's own idle unload, not by stopping it,
      # so probing it is safe: health checks are not inference and neither
      # delay the unload nor reload the model.
      gatus.checkPath = "/health";
    };
    homepage-dashboard = {
      port = 8082;
      domain = "home";
      homepage.enable = false;
      homepage.group = "core";
      homepage.name = "Homepage";
      gatus.enable = true;
    };
    aria = {
      port = 6800;
      domain = "aria";
      homepage.group = "Media";
      homepage.name = "Aria2";
      homepage.icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/ariang.png";
      homepage.description = "Download manager";
      gatus.enable = false;
    };

    vaultwarden = {
      port = 8222;
      domain = "vault";
      homepage.group = "System";
      homepage.name = "Vaultwarden";
      homepage.description = "Password manager";
      homepage.icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/vaultwarden.png";
      # LAN + tailnet only: push-status probes loopback, and the VPS status
      # page has no external-endpoint token for it. See AGENTS.md.
      gatus.enable = false;
    };
  };
}
