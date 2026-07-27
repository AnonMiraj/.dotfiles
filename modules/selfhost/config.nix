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
    };
  };
}
