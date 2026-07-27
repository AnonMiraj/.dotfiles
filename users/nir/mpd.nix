{
  config,
  pkgs,
  lib,
  ...
}: {
  services.mpd = {
    enable = true;

    musicDirectory = "~/Music";
    network.listenAddress = "127.0.0.1";
    extraConfig = ''
      auto_update "yes"
      restore_paused "yes"
      max_output_buffer_size "16384"

      audio_output {
        type            "pipewire"
        name            "Pipewire Output"
      }

      audio_output {
        type            "fifo"
        name            "my_fifo"
        path            "/tmp/mpd.fifo"
        format          "44100:16:2"
      }
      playlist_directory "~/.config/mpd/playlists"
    '';
  };
}
