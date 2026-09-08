{
  config,
  lib,
  pkgs,
  ...
}: {
  # SSH "hop" to home: `ssh home@152.53.81.54` auto-forwards through the frp
  # tunnel (127.0.0.1:2222) into the home box (as nir). No port exposed.
  users.users.home = {
    isSystemUser = true;
    description = "ssh hop -> home (frp tunnel :2222)";
    group = "users";
    home = "/home/home";
    createHome = true;
    openssh.authorizedKeys.keys = [
      # laptop key(s) allowed to hop
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbSLj6t8hoUSosDojStzA/o04KeeHo0gy9k3X8Q+rvx nabilmalek48@gmail.com"
    ];
  };

  # Every login as `home` is forced straight through the tunnel to home.
  services.openssh.extraConfig = ''
    Match User home
      ForceCommand /run/current-system/sw/bin/ssh -T -p 2222 -i /home/home/.ssh/hop -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null nir@127.0.0.1
  '';
}