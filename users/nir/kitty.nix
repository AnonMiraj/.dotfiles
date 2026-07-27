{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.kitty = {
    enable = true;

    settings = {
      # Appearance & Window
      background_opacity = "0.8";
      dynamic_background_opacity = true;
      confirm_os_window_close = 0;
      linux_display_server = "auto";
      cursor_trail = 10;
      enable_audio_bell = false;

      # Fonts
      font_family = "FiraCode Nerd Font Mono";
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      font_size = 16;

      # Shell & Behavior
      shell = "fish";
      scrollback_lines = 2000;
      wheel_scroll_min_lines = 1;
      force_ltr = true;
      allow_remote_control = true;
      listen_on = "unix:@mykitty";

      # Scrollback
      scrollback_pager = "nvim -c 'set ft=man' -";
      strip_trailing_spaces = "smart";

      # Layout
      enabled_layouts = "splits,stack";

      # Tab bar
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_bar_align = "left";
      tab_bar_min_tabs = 2;
      tab_bar_margin_width = 0;
      tab_bar_margin_height = "2.5 1.5";
      inactive_tab_font_style = "normal";
      active_tab_font_style = "bold";
      tab_activity_symbol = " ● ";
      tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title[:30]}{title[30:] and '…'} [{index}]";
      active_tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title[:30]}{title[30:] and '…'} [{index}]";
    };

    extraConfig = ''
      # Editor
      editor nvim

      # Keybindings: Tabs
      map alt+n          new_tab_with_cwd
      map alt+shift+n    new_tab
      map alt+r          set_tab_title
      map alt+x          close_tab
      map alt+tab        next_tab
      map alt+]          move_tab_forward
      map alt+[          move_tab_backward
      map alt+1          goto_tab 1
      map alt+2          goto_tab 2
      map alt+3          goto_tab 3
      map alt+4          goto_tab 4
      map alt+5          goto_tab 5
      map alt+6          goto_tab 6

      # Keybindings: Zoom
      map ctrl+plus      change_font_size all +1
      map ctrl+equal     change_font_size all +1
      map ctrl+kp_add    change_font_size all +1
      map ctrl+minus     change_font_size all -1
      map ctrl+0         change_font_size all 0

      # Keybindings: Sessions & Windows
      map ctrl+shift+enter launch --cwd=current --type=os-window
      map f1             save_as_session

      # Theme — included at runtime for hot-reload
      include themes/noctalia.conf
    '';
  };
}
