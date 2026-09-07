{
  config,
  lib,
  pkgs,
  ...
}: {
  # QEMU Guest Agent — lets netcup's hypervisor talk to the guest (graceful
  # shutdown/power management). Fixes the "QEMU Guest Agent is not running"
  # warning in the panel.
  services.qemuGuest.enable = true;
}