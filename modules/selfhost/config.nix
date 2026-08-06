{...}: {
  networking.firewall.allowedTCPPorts = [53 80 443 6767 6768 8880];
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
      domain = "niro.lan";
      local = "/niro.lan/";
      address = [
        "/niro.lan/192.168.1.6"
      ];
      # Bind only to loopback + LAN iface, not 0.0.0.0:53. Leaves
      # 10.42.0.1:53 free for NetworkManager's hotspot (shared) dnsmasq.
      interface = [
        "lo"
        "enp43s0"
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
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };




  # bind-dynamic above frees 0.0.0.0:53 for
  # NM hotspot dnsmasq (see modules/selfhost/hotspot.nix).
}
