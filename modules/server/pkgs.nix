{
  config,
  lib,
  pkgs,
  ...
}: {
  # VPS-only packages (almiraj). GLOBAL set lives in modules/shared.nix;
  # PC-only (desktop niro) set lives in modules/packages/*.
  environment.systemPackages = with pkgs; [
    vim # quick edit on the server
    btrfs-progs # btrfs subvolume snapshots
    yazi # terminal file manager

    # Networking / diagnostics
    tcpdump
    nmap
    nload
    iftop
    iperf3
    ethtool
    netselect

    # System monitoring (sysstat and btop are in the GLOBAL set)
    iotop

    # Misc ops
    pv
    yq
    docker-compose
    rclone
    restic
    borgbackup
  ];
}
