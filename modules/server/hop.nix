{
  config,
  lib,
  pkgs,
  ...
}: {
  # SSH "hop" to home: `ssh home@152.53.81.54 [cmd]` transparently tunnels through
  # the frp link (127.0.0.1:2222) into the home box as nir. The user's login shell
  # is a wrapper that runs `ssh ... nir@127.0.0.1 "$@"`, so commands pass through.
  # The hop key lives at /home/home/.ssh/hop (generated on the box).
  users.users.home = {
    isSystemUser = true;
    description = "ssh hop to home via frp tunnel";
    group = "users";
    home = "/home/home";
    createHome = true;
    # wrapper that execs into the tunnel to home
    shell = "/home/home/.ssh/hop-shell";
    openssh.authorizedKeys.keys = [
      # laptop key(s) allowed to hop
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbSLj6t8hoUSosDojStzA/o04KeeHo0gy9k3X8Q+rvx nabilmalek48@gmail.com"
      # phone (Termux) key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCrzgiSAX7lDWlWsfuoMrA87y7K58Y99QfGSWk3Ng+s u0_a291@localhost"
    ];
  };
}