{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.zathura = {
    enable = true;

    options = {
      # Noctalia theme colors
      default_bg = "rgba(230, 230, 230, 0.8)";
      default_fg = "#1b1818";
      recolor_lightcolor = "rgba(0,0,0,0)";
      recolor_darkcolor = "#1b1818";
      statusbar_bg = "#faf9f9";
      statusbar_fg = "#6c1313";
      inputbar_bg = "#faf9f9";
      inputbar_fg = "#6c1313";
      notification_bg = "#faf9f9";
      notification_fg = "#6c1313";
      notification_error_bg = "#faf9f9";
      notification_error_fg = "#fd4663";
      notification_warning_bg = "#ad1f1f";
      notification_warning_fg = "#f7bbc4";
      highlight_color = "rgba(173, 31, 31, 0.5)";
      highlight_active_color = "rgba(130, 23, 23, 0.5)";
      index_bg = "rgba(0,0,0,0)";
      index_fg = "#1b1818";
      index_active_bg = "#6c1313";
      index_active_fg = "#faf9f9";
      completion_bg = "#faf9f9";
      completion_fg = "#6c1313";
      completion_group_bg = "#faf9f9";
      completion_group_fg = "#6c1313";
      completion_highlight_fg = "#faf9f9";
      completion_highlight_bg = "#6c1313";

      # Behavior
      selection_clipboard = "clipboard";
      incremental_search = true;
      search_hadjust = true;
      adjust_open = "width";
      font = "FiraCode Nerd Font 12";
      guioptions = "none";
      recolor = "true";
      recolor_reverse_video = "true";
      recolor_keephue = "true";
    };

    mappings = {
      "z" = "zoom in";
      "Z" = "zoom out";
      "D" = "toggle_page_mode";
      "u" = "scroll half-up";
      "d" = "scroll half-down";
      "f" = "toggle_fullscreen";
      "b" = "toggle_statusbar";
      "H" = "adjust_window best-fit";
      "W" = "adjust_window width";
      "i" = "recolor";
      "R" = "rotate";
      "K" = "zoom in";
      "J" = "zoom out";
      "p" = "print";
      "g" = "goto top";
      "<C-r>" = "reload";
    };

    extraConfig = ''
      map e exec "xournalpp \"$FILE\""
    '';
  };
}
