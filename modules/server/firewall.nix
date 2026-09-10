{
  config,
  lib,
  pkgs,
  ...
}: {
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      80
      443
    ];
    allowPing = true;
  };

  # SSH: keys only, no password. Account policy (admin wheel) is in accounts.nix.
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "no";
  };
}