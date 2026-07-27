{
  config,
  pkgs,
  lib,
  ...
}: {
  # No HM module for nsxiv — use xdg.configFile for key-handler script
  xdg.configFile."nsxiv/exec/key-handler" = {
    executable = true;
    text = ''
      #!/bin/sh

      while read file
      do
        case "$1" in
          "c") wl-copy < "$file" ;;
          "w") noctalia msg  wallpaper-set "$file";;
          "r") convert "$file" -rotate 90 /tmp/out.jpg ;;
          "m") curl -F"file=@$file" 0x0.st | wl-copy ;;
          "i") notify-send -i $file "File information" "$(mediainfo $file)" ;;
          "y") readlink -f "$file" | wl-copy && notify-send "$(readlink -f "$file") copied to clipboard" ;;
        esac
      done
    '';
  };
}
