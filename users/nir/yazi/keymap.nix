{lib, ...}: {
  programs.yazi.keymap = {
    input.prepend_keymap = [
      {
        on = ["<Esc>"];
        run = "close";
        desc = "Cancel input";
      }
    ];

    completion.prepend_keymap = [
      {
        on = "<C-k>";
        run = "arrow -1";
        desc = "Move cursor up";
      }
      {
        on = "<C-j>";
        run = "arrow 1";
        desc = "Move cursor down";
      }
    ];

    mgr = {
      prepend_keymap = [
        {
          on = ["g" "a"];
          run = "shell 'adb-sync %s /sdcard/acv/ && notify-send ADB \"Files synced successfully\" || notify-send ADB \"Sync failed\"' --confirm";
          desc = "ADB sync";
        }
        {
          on = "w";
          run = "shell \"fish\" --block --confirm";
          desc = "Open shell here";
        }
        {
          on = "<C-w>";
          run = "tasks:show";
          desc = "Show task manager";
        }
        {
          on = "<C-z>";
          run = "plugin ouch";
          desc = "Archive selected files";
        }
        {
          on = "<A-k>";
          run = "arrow -5";
          desc = "Move up half page";
        }
        {
          on = "<A-j>";
          run = "arrow 5";
          desc = "Move down half page";
        }
        # Smart enter — fast subdir entry
        {
          on = "l";
          run = "plugin smart-enter";
          desc = "Smart enter";
        }
        # Zoxide jump
        {
          on = "z";
          run = "plugin fuzzy-search zoxide";
          desc = "Zoxide jump";
        }
        # Fzf search
        {
          on = "<C-f>";
          run = "plugin fuzzy-search fd";
          desc = "Fzf file search";
        }
        # Grep text search
        {
          on = "Z";
          run = "plugin fr rg";
          desc = "Fzf grep search";
        }
        # Rename
        {
          on = ["C"];
          run = "rename --cursor=start --empty=stem";
          desc = "Rename from start";
        }
        {
          on = ["i"];
          run = "rename --cursor=before_ext --empty=stem";
          desc = "Rename before ext";
        }
        {
          on = ["a"];
          run = "rename";
          desc = "Rename after ext";
        }
        {
          on = ["B"];
          run = "bulk_rename";
          desc = "Bulk rename";
        }
        {
          on = ["<C-n>"];
          run = "create";
          desc = "Create file/dir";
        }
        {
          on = ["c" "m"];
          run = "plugin chmod";
          desc = "Chmod";
        }
        {
          on = "<C-d>";
          run = "shell 'ripdrag %s -n -a -x 2>/dev/null &' --confirm";
          desc = "Drag files";
        }
        {
          on = "d";
          run = "yank --cut";
          desc = "Cut";
        }
        {
          on = "D";
          run = "remove";
          desc = "Trash";
        }
        {
          on = "<C-g>";
          run = "plugin vcs-files";
          desc = "Git changes";
        }
        {
          on = "F";
          run = "filter --smart";
          desc = "Filter files";
        }
        {
          on = ["R" "b"];
          run = "plugin recycle-bin";
          desc = "Recycle Bin";
        }
        {
          on = ["M"];
          run = "plugin sshfs -- menu";
          desc = "SSHFS";
        }
        {
          on = "f";
          run = "plugin fchar start";
          desc = "Jump to char";
        }
        {
          on = "g";
          run = "parent";
          desc = "Go to parent";
        }
        {
          on = "K";
          run = "plugin parent-arrow -1";
          desc = "Parent arrow up";
        }
        {
          on = "J";
          run = "plugin parent-arrow 1";
          desc = "Parent arrow down";
        }
        {
          on = "<C-r>";
          run = "plugin duck-radar";
          desc = "Recent files";
        }
        {
          on = ".";
          run = ["hidden toggle" "plugin pref-by-location -- save"];
          desc = "Toggle hidden";
        }
        # Linemode
        {
          on = ["m" "s"];
          run = ["linemode size" "plugin pref-by-location -- save"];
          desc = "Linemode: size";
        }
        {
          on = ["m" "p"];
          run = ["linemode permissions" "plugin pref-by-location -- save"];
          desc = "Linemode: permissions";
        }
        {
          on = ["m" "b"];
          run = ["linemode btime" "plugin pref-by-location -- save"];
          desc = "Linemode: btime";
        }
        {
          on = ["m" "m"];
          run = ["linemode mtime" "plugin pref-by-location -- save"];
          desc = "Linemode: mtime";
        }
        {
          on = ["m" "o"];
          run = ["linemode owner" "plugin pref-by-location -- save"];
          desc = "Linemode: owner";
        }
        {
          on = ["m" "n"];
          run = ["linemode none" "plugin pref-by-location -- save"];
          desc = "Linemode: none";
        }
        # Sort — lower=forward, upper=reverse
        {
          on = ["," "t"];
          run = ["sort mtime --reverse" "linemode mtime" "plugin pref-by-location -- save"];
          desc = "Sort mtime (rev)";
        }
        {
          on = ["," "T"];
          run = ["sort mtime --reverse=no" "linemode mtime" "plugin pref-by-location -- save"];
          desc = "Sort mtime";
        }
        {
          on = ["," "m"];
          run = ["sort mtime --reverse=no" "linemode mtime" "plugin pref-by-location -- save"];
          desc = "Sort mtime";
        }
        {
          on = ["," "M"];
          run = ["sort mtime --reverse" "linemode mtime" "plugin pref-by-location -- save"];
          desc = "Sort mtime (rev)";
        }
        {
          on = ["," "b"];
          run = ["sort btime --reverse=no" "linemode btime" "plugin pref-by-location -- save"];
          desc = "Sort btime";
        }
        {
          on = ["," "B"];
          run = ["sort btime --reverse" "linemode btime" "plugin pref-by-location -- save"];
          desc = "Sort btime (rev)";
        }
        {
          on = ["," "e"];
          run = ["sort extension --reverse=no" "plugin pref-by-location -- save"];
          desc = "Sort by ext";
        }
        {
          on = ["," "E"];
          run = ["sort extension --reverse" "plugin pref-by-location -- save"];
          desc = "Sort by ext (rev)";
        }
        {
          on = ["," "a"];
          run = ["sort alphabetical --reverse=no" "plugin pref-by-location -- save"];
          desc = "Sort alpha";
        }
        {
          on = ["," "A"];
          run = ["sort alphabetical --reverse" "plugin pref-by-location -- save"];
          desc = "Sort alpha (rev)";
        }
        {
          on = ["," "n"];
          run = ["sort natural --reverse=no" "plugin pref-by-location -- save"];
          desc = "Sort natural";
        }
        {
          on = ["," "N"];
          run = ["sort natural --reverse" "plugin pref-by-location -- save"];
          desc = "Sort natural (rev)";
        }
        {
          on = ["," "s"];
          run = ["sort size --reverse=no" "linemode size" "plugin pref-by-location -- save"];
          desc = "Sort size";
        }
        {
          on = ["," "S"];
          run = ["sort size --reverse" "linemode size" "plugin pref-by-location -- save"];
          desc = "Sort size (rev)";
        }
        {
          on = ["," "r"];
          run = ["sort random --reverse=no" "plugin pref-by-location -- save"];
          desc = "Sort random";
        }
        # What-size — bound to ,z (free slot) since ,S is reverse sort
        {
          on = ["," "z"];
          run = "plugin what-size";
          desc = "Calc size of selection";
        }
        # Paste / copy with ucp notifications
        {
          on = "p";
          run = "plugin ucp paste notify";
          desc = "Paste";
        }
        {
          on = "y";
          run = "plugin ucp copy notify";
          desc = "Copy";
        }
      ];

      append_keymap = [
        {
          on = "e";
          run = "open";
          desc = "Open files";
        }
        {
          on = "E";
          run = "open --interactive";
          desc = "Open interactive";
        }
        {
          on = ["g" "n"];
          run = "cd ~/.config/nvim/";
          desc = "NVIM dir";
        }
        {
          on = ["g" "v"];
          run = "cd ~/videos/";
          desc = "Videos";
        }
        {
          on = ["g" "p"];
          run = "cd ~/pictures/";
          desc = "Pictures";
        }
        {
          on = ["g" "s"];
          run = "cd ~/pictures/Screenshots/";
          desc = "Screenshots";
        }
        {
          on = ["g" "D"];
          run = "cd ~/documents/";
          desc = "Documents";
        }
      ];
    };
  };
}
