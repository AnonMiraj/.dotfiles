# Tailscale client on niro, joined to the self-hosted Headscale server.
#
# niro only advertises my.lan.subnet while it is on the home network, so
# tailnet devices reach the split-brain `*.${config.my.lan.domain}` names
# when home and cannot be blackholed through niro when it travels.
# Headscale hands out the auth key; store it in sops.
{
  config,
  lib,
  pkgs,
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
      ];
    };

    # Track NetworkManager: advertise the home route only on the home
    # connections, clear it everywhere else.
    networking.networkmanager.dispatcherScripts = [
      {
        source = pkgs.writeShellScript "50-tailscale-home-route" ''
          case "$2" in
            up|down|connectivity-change) ;;
            *) exit 0 ;;
          esac
          # Let NetworkManager finish activating the connection.
          ${pkgs.coreutils}/bin/sleep 3
          if ${pkgs.networkmanager}/bin/nmcli -t -f NAME connection show --active | ${pkgs.gnugrep}/bin/grep -qxE 'Sigma|Wired connection 1'; then
            ${pkgs.tailscale}/bin/tailscale set --advertise-routes=${config.my.lan.subnet} || true
          else
            ${pkgs.tailscale}/bin/tailscale set --advertise-routes= || true
          fi
        '';
        type = "basic";
      }
    ];

    # NixOS' default nftables rules drop forwarded packets; allow the
    # tailnet -> LAN direction for the advertised my.lan.subnet route.
    networking.firewall.extraForwardRules =
      lib.concatMapStrings (iface: ''
        iifname "tailscale0" oifname "${iface}" accept
      '')
      config.my.lan.interfaces;
  };
}
