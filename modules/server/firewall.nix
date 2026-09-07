{
  config,
  lib,
  pkgs,
  ...
}: {
  # Default-deny firewall (inventory §9: current ufw is effectively wide open).
  # Only explicit ports open; per-service modules add theirs.
  networking.firewall = {
    enable = true;
    # Allow SSH + HTTPS always; mail/frp/3x-ui ports are added by their modules.
    allowedTCPPorts = [
      22
      80
      443
    ];
    # tr/a broadcasts not needed on a VPS.
    allowPing = true;
  };

  # SSH: keys only, no password. Account policy (admin wheel) is in accounts.nix.
  services.openssh = {
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
  };
}