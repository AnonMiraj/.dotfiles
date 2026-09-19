# Tailscale client on niro, joined to the self-hosted Headscale server.
#
# niro advertises my.lan.subnet, so tailnet devices can reach the split-brain
# `*.${config.my.lan.domain}` names (and the rest of the home LAN) while away
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
        "--advertise-routes=${config.my.lan.subnet}"
      ];
    };

    # NixOS' default nftables rules drop forwarded packets; allow the
    # tailnet -> LAN direction for the advertised my.lan.subnet route.
    networking.firewall.extraForwardRules = ''
      iifname "tailscale0" oifname "${config.my.lan.interface}" accept
    '';
  };
}
