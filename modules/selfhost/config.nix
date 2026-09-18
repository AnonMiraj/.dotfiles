# Local name resolution for *.niro.lan: Avahi, dnsmasq and /etc/hosts.
{
  config,
  lib,
  ...
}: let
  h = import ../../lib/selfhost.nix {inherit lib config;};
  inherit (lib) mapAttrsToList;
  inherit (h) domain domainOf;
in {
  # 8880 is gone: Kokoro now listens on loopback behind its wake socket, so
  # only Caddy (local) and frpc reach it.
  networking.firewall.allowedTCPPorts = [53 80 443 6767 6768];
  networking.firewall.allowedUDPPorts = [53];

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
      # Bind only to loopback + LAN iface, not 0.0.0.0:53. Leaves
      # 10.42.0.1:53 free for NetworkManager's hotspot (shared) dnsmasq.
      interface = [
        "lo"
        config.my.lan.interface
      ];
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

  # Resolve every generated vhost to this host, so *.niro.lan works without
  # going through dnsmasq for names the browser already knows about.
  networking.hosts."127.0.0.1" =
    (mapAttrsToList (_: svc: domainOf svc) config.my.services)
    ++ (builtins.attrNames config.my.caddy.extraVhosts);
}
