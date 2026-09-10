{
  config,
  lib,
  pkgs,
  ...
}: {
  # VPS account policy (per migration plan): no root login, one wheel `admin`
  # with passwordless sudo. All user accounts live here.
  security.sudo.wheelNeedsPassword = false;

  users.mutableUsers = false;

  # Lock root login outright.
  users.users.root.hashedPassword = "!";

  users.users.admin = {
    isNormalUser = true;
    description = "VPS admin";
    extraGroups = ["wheel" "docker"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbSLj6t8hoUSosDojStzA/o04KeeHo0gy9k3X8Q+rvx"
    ];
  };

  # NOT in wheel → no sudo.
  users.users.dev = {
    isNormalUser = true;
    description = "normal user (docker/journal log access only)";
    extraGroups = ["docker" "systemd-journal"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbSLj6t8hoUSosDojStzA/o04KeeHo0gy9k3X8Q+rvx"
      # provided second key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKnVCrOMY5uA8I0vhWajRWVFc38/wF2bJHBO/zT3YM09"
    ];
  };

  # ssh hop to home via the frp tunnel (127.0.0.1:2222). Clients use ProxyJump:
  #   Host home
  #     HostName 127.0.0.1
  #     Port 2222
  #     ProxyJump admin@almiraj.xyz
  # The hop key lives at /home/home/.ssh/hop (generated on the box).
  users.users.home = {
    isNormalUser = true;
    description = "ssh hop to home via frp tunnel";
    group = "users";
    home = "/home/home";
    createHome = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbSLj6t8hoUSosDojStzA/o04KeeHo0gy9k3X8Q+rvx"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCrzgiSAX7lDWlWsfuoMrA87y7K58Y99QfGSWk3Ng+s u0_a291@localhost"
    ];
  };
}
