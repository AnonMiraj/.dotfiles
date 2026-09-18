{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    lutris
    umu-launcher
    wine
    steam
  ];
}
