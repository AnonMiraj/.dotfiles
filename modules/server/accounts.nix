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
}
