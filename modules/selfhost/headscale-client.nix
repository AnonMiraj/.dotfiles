# Tailscale client on niro, joined to the self-hosted Headscale server.
#
# niro advertises 192.168.1.0/24, so tailnet devices can reach the split-brain
# `*.lab.almiraj.xyz` names (and the rest of the home LAN) while away from
# home. Headscale hands out the auth key; store it in sops.
{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.my.lan.headscale.enable {
    sops.secrets."headscale-auth-key" = {};

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      openFirewall = true;
      authKeyFile = config.sops.secrets."headscale-auth-key".path;
      extraUpFlags = [
        "--login-server"
        "https://headscale.almiraj.xyz"
        "--advertise-routes=192.168.1.0/24"
      ];
    };

    # NixOS' default nftables rules drop forwarded packets; allow the
    # tailnet -> LAN direction for the advertised 192.168.1.0/24 route.
    networking.firewall.extraForwardRules = ''
      iifname "tailscale0" oifname "${config.my.lan.interface}" accept
    '';
  };
}
