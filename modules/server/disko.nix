{
  config,
  lib,
  pkgs,
  ...
}: {
  # ZFS root via disko — Decision G1 = A (persistent ZFS root, unencrypted,
  # unattended boot). Imported in almiraj/default.nix via inputs.disko.

  # Stable host id required by ZFS. Derive from /etc/machine-id after install
  # (or keep this fixed value; it must not change).
  networking.hostId = "0b46ea0b";

  boot.supportedFilesystems = ["zfs"];
  boot.zfs.forceImportRoot = true;

  # Swap on zram (VPS had memory pressure; no disk swap), and cap the ZFS
  # ARC so it doesn't starve Dovecot/Rspamd on the 8 GiB box.
  zramSwap.enable = true;
  boot.kernelParams = ["zfs.zfs_arc_max=1073741824"]; # 1 GiB ARC


  # UEFI boot loader: GRUB-EFI as a REMOVABLE binary on the ESP. Robust with a
  # ZFS root and netcup VM UEFI (avoids systemd-boot's ESP-mountpoint check
  # failing during the install chroot, and removable EFI needs no NVRAM entry).
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
    zfsSupport = true;
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
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };

    zpool.rpool = {
      type = "zpool";
      rootFsOptions = {
        canmount = "off";
        compression = "zstd";
        atime = "off";
        xattr = "sa";
        acltype = "posixacl";
        "com.sun:auto-snapshot" = "false";
      };
      mountpoint = null;
      datasets = {
        "root" = {
          type = "zfs_fs";
          options.canmount = "off";
        };
        "root/nixos" = {
          type = "zfs_fs";
          mountpoint = "/";
        };
        "local" = {
          type = "zfs_fs";
          options.canmount = "off";
        };
        "local/nix" = {
          type = "zfs_fs";
          mountpoint = "/nix";
        };
        "local/docker" = {
          type = "zfs_fs";
          mountpoint = "/var/lib/docker";
        };
      };
    };
  };
}