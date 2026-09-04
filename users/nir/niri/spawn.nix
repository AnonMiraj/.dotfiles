{pkgs, inputs, ...}: let
  niri-zoomd = "${inputs.niri-zoom.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/niri-zoomd";
in {
  programs.niri.settings.spawn-at-startup = [
    {argv = ["xwayland-satellite"];}
    {argv = ["wl-paste" "--type" "text" "--watch" "cliphist" "store"];}
    {argv = ["wl-paste" "--type" "image" "--watch" "cliphist" "store"];}
    {argv = ["trash-empty" "30"];}
    {argv = ["mpd"];}
    {argv = ["kdeconnectd"];}
    {sh = "sleep 5 && mpd-mpris";}
    {argv = ["~/.local/bin/lowbattery.sh"];}
    {argv = ["transmission-daemon"];}
    {argv = [niri-zoomd];}
  ];
}
