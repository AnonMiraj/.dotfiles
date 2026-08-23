# Service metadata template:
# servicename = {
#   port = 1234;                        # required — local port
#   domain = "sub";                     # required — subdomain.niro.lan
#   proxyTarget = "localhost:1234";     # optional — override proxy target
#   homepage.group = "Media";           # optional — Media / Dev / System
#   homepage.name = "My Service";       # optional — display name (default: capitalized attr name)
#   homepage.description = "...";       # optional
#   homepage.icon = "https://...";      # optional — icon URL
#   gatus.enable = true;                # optional — default true
#   gatus.checkPath = "/health";        # optional — default "/"
#   frp.enable = true;                  # optional — expose via FRP
#   frp.remotePort = 8881;              # optional — default same as port
# };
{...}: {
  my.services = {
    ssh = {
      port = 22;
      domain = "ssh";
      homepage.enable = false;
      gatus.enable = false;
      frp.enable = true;
      frp.remotePort = 2222;
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
      frp.enable = true;
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
      homepage.icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/kokoro.png";
      homepage.description = "TTS engine";
      gatus.checkPath = "/health";
      frp.enable = true;
      frp.remotePort = 8881;
    };
    homepage-dashboard = {
      port = 8082;
      domain = "home";
      homepage.enable = false;
      homepage.group = "core";
      homepage.name = "Homepage";
      gatus.enable = true;
    };
    v2raya = {
      port = 2017;
      domain = "vpn";
      homepage.group = "System";
      homepage.name = "v2rayA";
      homepage.icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@main/png/v2ray.png";
      homepage.description = "V2Ray / Xray Web Client";
      gatus.enable = false;
      frp.enable = false;
    };
  };
}
