{
  config,
  lib,
  pkgs,
  ...
}: {
  # VPS-only packages (almiraj). GLOBAL set lives in modules/base.nix;
  # PC-only (desktop niro) set lives in modules/pkgs.nix.
  environment.systemPackages = with pkgs; [
    vim # quick edit on the server
    yazi # terminal file manager (neovim already in the GLOBAL set)


    # Networking / diagnostics
    tcpdump
    nmap
    nload
    iftop
    iperf3
    ethtool
    netselect

    # System monitoring
    sysstat # iostat / sar / pidstat
    iotop
    btop

    # Misc ops
    pv
    yq
    docker-compose
    rclone
    restic
    borgbackup
  ];
}