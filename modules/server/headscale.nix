# Headscale — self-hosted Tailscale coordination server.
#
# Runs on the VPS behind Caddy at https://headscale.almiraj.xyz. Clients point
# at that URL (Tailscale apps: "Use an alternate server"). Home `niro` joins
# as a subnet router for 192.168.1.0/24, so tailnet devices can reach the
# split-brain `*.lab.almiraj.xyz` names while off the home LAN.
#
# DNS: MagicDNS uses `niro.internal` for tailnet hostnames, global DNS falls
# back to Cloudflare, and `lab.almiraj.xyz` is split to Niro's dnsmasq
# (192.168.1.6) once the subnet route is approved.
{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.my.server.headscale.enable {
    services.headscale = {
      enable = true;
      # qBittorrent owns 8080 on the VPS.
      port = 8081;

      settings = {
        server_url = "https://headscale.almiraj.xyz";

        dns = {
          magic_dns = true;
          base_domain = "niro.internal";
          override_local_dns = true;
          nameservers = {
            global = ["1.1.1.1" "1.0.0.1"];
            # Split DNS: tailnet clients send *.lab.almiraj.xyz to Niro's
            # dnsmasq through the approved 192.168.1.0/24 subnet route.
            split."lab.almiraj.xyz" = ["192.168.1.6"];
          };
          search_domains = ["lab.almiraj.xyz"];
        };

        log.level = "info";
      };
    };

    # Caddy terminates TLS for the control server. The public site module
    # already enables Caddy on this host; mkDefault keeps a standalone
    # enable build from failing.
    services.caddy.enable = lib.mkDefault true;
    services.caddy.virtualHosts."headscale.almiraj.xyz" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:8081 {
          header_up Host {host}
          header_up X-Real-IP {remote}
        }
      '';
    };

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
