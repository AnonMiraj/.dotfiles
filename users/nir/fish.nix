{ ... }: {
  programs.fish = {
    enable = true;
    preferAbbrs = true;

    shellAliases = {
      # System commands with sudo
      mount = "sudo mount";
      umount = "sudo umount";
      sv = "sudo sv";
      updatedb = "sudo updatedb";
      su = "sudo su";
      shutdown = "sudo shutdown";
      poweroff = "sudo poweroff";
      reboot = "sudo reboot";

      # Sensible default flags
      cp = "cp -iv";
      mv = "mv -iv";
      rm = "rm -vI";
      bc = "bc -ql";
      rsync = "rsync -vrPlu";
      mkd = "mkdir -pv";
      yt = "yt-dlp --embed-metadata -i";
      yta = "yt -x -f bestaudio/best";
      ytt = "yt --skip-download --write-thumbnail";
      ffmpeg = "ffmpeg -hide_banner";
      ":q" = "exit";

      # Colorized / enhanced commands
      ls = "eza -a --icons --group-directories-first";
      ll = "eza -al --icons";
      lt = "eza -a --tree --level=1 --icons";
      grep = "grep --color=auto";
      diff = "diff --color=auto";
      ccat = "highlight --out-format=ansi";
      ip = "ip -color=auto";

      # Shortcuts
      ka = "killall";
      g = "git";
      z = "zathura";

      # Misc
      genpasswd = "openssl rand -base64 21";
    };

    shellAbbrs = {
      gd = "git diff";
      ga = "git add .";
      gc = "git commit -am";
      gl = "git log";
      gs = "git status";
      gst = "git stash";
      gsp = "git stash pop";
      gp = "git push";
      gpl = "git pull";
      gsw = "git switch";
      gsm = "git switch main";
      gb = "git branch";
      gbd = "git branch -d";
      gco = "git checkout";
      gsh = "git show";
      l = "ls";
      ll = "ls -l";
      la = "ls -a";
      lla = "ls -la";
    };

    functions = {
      edit_cmdline_in_nvim = ''
        set -l tmpfile (mktemp)
        commandline > $tmpfile
        $EDITOR $tmpfile > /dev/null 2>&1
        commandline -r (string trim --right (cat $tmpfile))
        rm -f $tmpfile > /dev/null 2>&1
      '';
    };

    binds = {
      "\\ce".command = "edit_cmdline_in_nvim";
    };

    shellInit = ''
      # Suppress welcome message
      set -g fish_greeting ""

      # ~/.local/bin subdirs → PATH
      if test -d "$HOME/.local/bin"
          for dir in (find $HOME/.local/bin -type d)
              set -gx PATH $PATH $dir
          end
      end

      # Cargo env
      source "$HOME/.local/share/cargo/env.fish"

      # Script compatibility
      set -gx SHELL /bin/sh

      # Env vars
      set -gx TERMINAL_PROG kitty
      set -gx READER zathura
      set -gx FILE lf
      set -gx WINEPREFIX "$HOME/.local/share/wineprefixes/default"
      set -gx WINEDLLPATH "/usr/lib/wine/x86_64-unix wine64"
      set -gx CARGO_HOME "$XDG_DATA_HOME/cargo"
      set -gx GOPATH "$XDG_DATA_HOME/go"
      set -gx PYTHONSTARTUP "$XDG_CONFIG_HOME/python/pythonrc"
      set -gx FZF_DEFAULT_OPTS "--layout=reverse --height 40%"
    '';

    interactiveShellInit = ''
      starship init fish | source
      command -v direnv &> /dev/null && direnv hook fish | source
      command -v zoxide &> /dev/null && zoxide init fish --cmd cd | source
      fzf --fish | source
      fish_vi_key_bindings
    '';
  };
}
