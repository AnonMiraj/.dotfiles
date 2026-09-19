# Local name resolution for the split-brain LAN zone: Avahi, dnsmasq, /etc/hosts.
{
  config,
  lib,
  ...
}: let
  h = import ../../lib/selfhost.nix {inherit lib config;};
  inherit (lib) mapAttrsToList;
  inherit (h) domain domainOf;
in {
  # 8880 is gone: Kokoro publishes on loopback only, so Caddy reaches it
  # without needing a firewall hole.
  networking.firewall.allowedTCPPorts = [80 443 6767 6768];
  # DNS (53) is not global: only the home subnet and the tailnet may
  # query dnsmasq, so a foreign Wi-Fi cannot use this box as a resolver.
  networking.firewall.extraInputRules = ''
    ip saddr ${config.my.lan.subnet} tcp dport 53 accept
    ip saddr ${config.my.lan.subnet} udp dport 53 accept
    iifname "tailscale0" tcp dport 53 accept
    iifname "tailscale0" udp dport 53 accept
  '';

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish.enable = true;
    publish.addresses = true;
    publish.workstation = true;
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      domain = domain;
      local = "/${domain}/";
      address = [
        "/${domain}/${config.my.lan.address}"
      ];
      # Do not let /etc/hosts influence dnsmasq answers. The local 127.0.0.1
      # entries below are for Niro itself; LAN clients must get the address=
      # answer (192.168.1.6), not loopback.
      no-hosts = true;
      # DNS-01 lives under the same zone, so dnsmasq would otherwise answer
      # the ACME challenge lookups itself (NXDOMAIN). Forward just that
      # name to public resolvers so lego can see the TXT record it created.
      server = [
        "/_acme-challenge.${domain}/1.1.1.1"
        "/_acme-challenge.${domain}/8.8.8.8"
      ];
      # Bind only to loopback + the LAN interfaces, not 0.0.0.0:53.
      interface =
        [
          "lo"
        ]
        ++ config.my.lan.interfaces;
      # bind-dynamic (not bind-interfaces): tolerates the iface not
      # existing yet at boot (eth0 → enp43s0 udev rename race) and
      # tracks address changes via netlink. bind-interfaces crashes
      # with "unknown interface" and hits start-limit-hit.
      bind-dynamic = true;
    };
  };

  # Best effort: start after the network is up, but don't hard-depend
  # on it — network-online.target can fire before the wired iface is
  # renamed/configured, which bind-dynamic now tolerates anyway.
  systemd.services.dnsmasq = {
    after = ["network-online.target"];
    wants = ["network-online.target"];
  };

  # Local-only loopback entries for Niro; dnsmasq ignores /etc/hosts
  # (no-hosts) and serves the address= answer above to everyone else.
  networking.hosts."127.0.0.1" =
    (mapAttrsToList (_: svc: domainOf svc) config.my.services)
    ++ (builtins.attrNames config.my.caddy.extraVhosts);
}
