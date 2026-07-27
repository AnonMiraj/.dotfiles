{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.yt-dlp = {
    enable = true;

    settings = {
      output = "~/YouTube/%(title)s.%(ext)s";
    };
  };
}
