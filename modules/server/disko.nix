{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.supportedFilesystems = ["btrfs"];

  zramSwap.enable = true;

  # UEFI boot: GRUB-EFI as a removable binary on the ESP. Robust on netcup VM
  # UEFI and needs no NVRAM entry.
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/vda"; # netcup ARM G11 virtio disk
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["umask=0077"];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = ["-f"]; # override existing
              # subvolumes → mountpoints
              subvolumes = {
                "/rootfs" = {
                  mountpoint = "/";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "/docker" = {
                  mountpoint = "/var/lib/docker";
                  mountOptions = ["compress=zstd" "noatime"];
                };
              };
            };
          };
        };
      };
    };
  };
}