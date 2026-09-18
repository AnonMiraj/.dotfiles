{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    lutris
    umu-launcher
    protonup-rs
    wine
    steam
  ];
}
