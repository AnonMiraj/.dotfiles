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
      bind-interfaces = true;
    };
  };

  # dnsmasq bind-interfaces above frees 0.0.0.0:53 for
  # NM hotspot dnsmasq (see modules/selfhost/hotspot.nix).
}
