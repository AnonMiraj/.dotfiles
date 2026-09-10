{
  config,
  lib,
  pkgs,
  ...
}: {
  services.qemuGuest.enable = true;
}