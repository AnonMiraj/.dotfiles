{
  config,
  lib,
  pkgs,
  ...
}: {
  # Normal (non-admin) user able to inspect docker + systemd logs.
  # In `docker` group → `docker logs <container>`; in `systemd-journal` → journalctl.
  # NOT in wheel → no sudo.
  users.users.dev = {
    isNormalUser = true;
    description = "normal user (docker/journal log access only)";
    extraGroups = ["docker" "systemd-journal"];
    openssh.authorizedKeys.keys = [
      # main admin/ops key (this repo's laptop)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbSLj6t8hoUSosDojStzA/o04KeeHo0gy9k3X8Q+rvx nabilmalek48@gmail.com"
      # provided second key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/VJwLe4Rnfi2KwtIJroKD31j+eWrzCjgkJGv3u883c"
    ];
  };
}