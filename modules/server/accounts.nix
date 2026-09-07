{
  config,
  lib,
  pkgs,
  ...
}: {
  # VPS account policy (per migration plan): no root login, one wheel `admin`
  # with passwordless sudo.
  security.sudo.wheelNeedsPassword = false;

  users.mutableUsers = false;

  # Lock root login outright.
  users.users.root.hashedPassword = "!";

  users.users.admin = {
    isNormalUser = true;
    description = "VPS admin";
    extraGroups = ["wheel" "docker"];
    openssh.authorizedKeys.keys = [
      # TODO: replace with a real pubkey (ezz) before Phase 3 cutover.
      "ssh-ed25519 AAAA...FIXME admin@almiraj"
    ];
  };
}