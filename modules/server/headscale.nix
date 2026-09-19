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
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.server.headscale.enable {
    services.headscale = {
      enable = true;
      # qBittorrent owns 8080 on the VPS.
      port = 8081;
      settings = {
        server_url = "https://headscale.almiraj.xyz";

        # Caddy terminates TLS on loopback; trust its X-Real-IP /
        # X-Forwarded-For so logs show the real client, not 127.0.0.1.
        trusted_proxies = ["127.0.0.1/32"];

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
        policy = {
          mode = "file";
          path = "/etc/headscale/policy.hujson";
        };

        # Embedded DERP relay, so tailnet traffic has a self-hosted path
        # when direct connections fail. TLS is terminated by Caddy on 443
        # via server_url; the STUN listener needs UDP 3478 open.
        derp.server = {
          enabled = true;
          region_id = 999;
          region_code = "almiraj";
          region_name = "Almiraj embedded";
          stun_listen_addr = "0.0.0.0:3478";
          verify_clients = true;
          automatically_add_embedded_derp_region = true;
        };

        log.level = "info";
      };
    };

    # Restrictive default: the phone may reach its own tailnet devices
    # and the home LAN through the niro subnet router on common service
    # ports only. Everything else is denied by default.
    environment.etc."headscale/policy.hujson".text = ''
      {
        "grants": [
          {
            "src": ["autogroup:member"],
            "dst": ["autogroup:self"],
            "ip": ["22", "53", "80", "443", "icmp:*"]
          },
          {
            "src": ["autogroup:member"],
            "dst": ["192.168.1.0/24"],
            "ip": ["22", "53", "80", "443", "icmp:*"]
          }
        ]
      }
    '';

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

    networking.firewall = {
      allowedTCPPorts = [80 443];
      allowedUDPPorts = [3478];
    };

    # Headscale loads the policy at startup only; restart it when the file
    # changes and expose a reload target for manual edits.
    systemd.services.headscale.restartTriggers = [
      config.environment.etc."headscale/policy.hujson".source
    ];
    systemd.services.headscale.serviceConfig.ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
  };
}
