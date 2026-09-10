{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.server.qbittorrent;
  # PBKDF2-HMAC-SHA512 (100k iters) hash for the WebUI password, generated
  # offline — see the "Web-UI-password-locked-on-qBittorrent-NO-X" wiki.
  # Plaintext password lives in secrets/vps.yaml (`qb-webui-password`).
  passwordHash = config.my.server.qbittorrent.passwordHash;
in {
  options.my.server.qbittorrent = {
    enable = lib.mkEnableOption "qbittorrent-nox BitTorrent client (public WebUI on qb.almiraj.xyz)";
    passwordHash = lib.mkOption {
      type = lib.types.str;
      description = "@ByteArray(...) PBKDF2 hash for the qBittorrent WebUI password.";
    };
  };

  config = lib.mkIf cfg.enable {

    services.qbittorrent = {
      enable = true;
      user = "qbittorrent";
      group = "qbittorrent";
      webuiPort = 8080;
      torrentingPort = 51414;
      # openFirewall left false: WebUI is fronted by Caddy (127.0.0.1:8080);
      # only the peer/listen port is exposed for incoming connections.
      serverConfig = {
        LegalNotice.Accepted = true;
        Preferences = {
          General.Locale = "en";
          WebUI = {
            Address = "*";
            Port = "8080";
            Username = "nir";
            Password_PBKDF2 = passwordHash;
            HostHeaderValidationEnabled = false; # behind Caddy reverse proxy
            CSRFProtection = false;
            MaxAuthenticationFailCount = 10;
            BanDuration = 3600;
            SessionTimeout = 3600;
            ClickjackingProtection = true;
          };
          Downloads = {
            SavePath = "/var/lib/qbittorrent/downloads";
            TempPath = "/var/lib/qbittorrent/downloads/.incomplete";
            TempPathEnabled = true;
            PreAllocation = false;
          };
          BitTorrent = {
            Session.DefaultSavePath = "/var/lib/qbittorrent/downloads";
          };
        };
      };
    };

    # qbittorrent runs a strict systemd sandbox (ProtectHome=yes,
    # ProtectSystem=full), so downloads must live under /var, not /home.
    systemd.tmpfiles.rules = [
      "d /var/lib/qbittorrent/downloads 0750 qbittorrent qbittorrent -"
    ];

    # Expose the peer port only (WebUI stays behind Caddy on 443). UDP carries
    # DHT + uTP traffic on the same port.
    networking.firewall.allowedTCPPorts = [51414];
    networking.firewall.allowedUDPPorts = [51414];

    # Public vhost for the WebUI, via the shared Caddy generator.
    my.publicServices.qb = {
      domain = "qb.almiraj.xyz";
      port = 8080;
      checkPath = "/";
      group = "media";
    };
  };
}