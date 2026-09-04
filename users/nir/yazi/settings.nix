{...}: {
  programs.yazi.settings = {
    mgr = {
      ratio = [1 4 3];
      sort_by = "natural";
      sort_dir_first = true;
      show_hidden = true;
      image_delay = 0;
    };

    opener = {
      image = [
        {
          run = "nsxiv -a %s";
          orphan = true;
          desc = "nsxiv";
          for = "linux";
        }
        {
          run = "xdg-open %s";
          orphan = true;
          desc = "xdg-open";
          for = "linux";
        }
      ];
      document = [
        {
          run = "zathura %s";
          orphan = true;
          desc = "zathura";
          for = "linux";
        }
        {
          run = "xournalpp %s";
          orphan = true;
          desc = "xournal++";
          for = "linux";
        }
        {
          run = "readest %s";
          orphan = true;
          desc = "readest";
          for = "linux";
        }
        {
          run = "xdg-open %s";
          orphan = true;
          desc = "xdg-open";
          for = "linux";
        }
      ];
      video = [
        {
          run = "mpv %s";
          orphan = true;
          desc = "mpv";
          for = "linux";
        }
        {
          run = "xdg-open %s";
          orphan = true;
          desc = "xdg-open";
          for = "linux";
        }
        {
          run = "mediainfo %s; echo 'Press enter to exit'; read _";
          block = true;
          desc = "mediainfo";
          for = "linux";
        }
      ];
      audio = [
        {
          run = "mpv %s";
          orphan = true;
          desc = "mpv";
          for = "linux";
        }
        {
          run = "xdg-open %s";
          orphan = true;
          desc = "xdg-open";
          for = "linux";
        }
        {
          run = "mediainfo %s; echo 'Press enter to exit'; read _";
          block = true;
          desc = "mediainfo";
          for = "linux";
        }
      ];
      text = [
        {
          run = "nvim %s";
          block = true;
          desc = "neovim";
          for = "linux";
        }
        {
          run = "kitty --detach nvim %s";
          orphan = true;
          desc = "neovim (detached)";
          for = "linux";
        }
        {
          run = "xdg-open %s";
          orphan = true;
          desc = "xdg-open";
          for = "linux";
        }
      ];
      folder = [
        {
          run = "nvim %s";
          block = true;
          desc = "neovim";
          for = "linux";
        }
        {
          run = "kitty --detach nvim %s";
          orphan = true;
          desc = "neovim (detached)";
          for = "linux";
        }
        {
          run = "fish -c 'lazygit -p %s1'";
          block = true;
          desc = "lazygit";
          for = "linux";
        }
        {
          run = "kitty %s";
          orphan = true;
          desc = "kitty";
          for = "linux";
        }
        {
          run = "xdg-open %s";
          orphan = true;
          desc = "xdg-open";
          for = "linux";
        }
      ];
      extract = [
        {
          run = "ouch d -y %s";
          desc = "Extract here with ouch";
          for = "unix";
        }
        {
          run = "xdg-open %s";
          orphan = true;
          desc = "xdg-open";
          for = "linux";
        }
      ];
      fallback = [
        {
          run = "nvim %s";
          block = true;
          desc = "neovim";
          for = "linux";
        }
        {
          run = "kitty --detach nvim %s";
          orphan = true;
          desc = "neovim (detached)";
          for = "linux";
        }
        {
          run = "xdg-open %s";
          orphan = true;
          desc = "xdg-open";
          for = "linux";
        }
      ];
    };

    open = {
      prepend_rules = [
        # Folder
        {
          url = "*/";
          use = ["folder" "reveal"];
        }
        # Documents / Ebooks
        {
          url = "*.pdf";
          use = ["document" "reveal"];
        }
        {
          mime = "application/pdf";
          use = ["document" "reveal"];
        }
        {
          url = "*.epub";
          use = ["document" "reveal"];
        }
        {
          mime = "application/epub+zip";
          use = ["document" "reveal"];
        }
        {
          mime = "application/x-mobipocket-ebook";
          use = ["document" "reveal"];
        }
        # Images
        {
          mime = "image/*";
          use = ["image" "reveal"];
        }
        # Video
        {
          mime = "video/*";
          use = ["video" "reveal"];
        }
        # Audio
        {
          mime = "audio/*";
          use = ["audio" "reveal"];
        }
        # Text & Code
        {
          mime = "text/*";
          use = ["text" "reveal"];
        }
        {
          mime = "application/{json,ndjson,javascript,wine-extension-ini}";
          use = ["text" "reveal"];
        }
        # Archives
        {
          mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}";
          use = ["extract" "reveal"];
        }
      ];
      append_rules = [
        {
          url = "*";
          use = ["fallback" "reveal"];
        }
      ];
    };

    plugin = {
      prepend_spotters = [
        {
          url = "video/*";
          run = "spot-video";
        }
        {
          mime = "image/*";
          run = "spot-image";
        }
        {
          mime = "audio/*";
          run = "spot";
        }
        {
          url = "*/";
          run = "spot";
        }
        {
          url = "*";
          run = "spot";
        }
      ];
      prepend_previewers = [
        {
          mime = "application/x-tar";
          run = "ouch";
        }
        {
          mime = "application/x-bzip2";
          run = "ouch";
        }
        {
          mime = "application/x-7z-compressed";
          run = "ouch";
        }
        {
          mime = "application/x-rar";
          run = "ouch";
        }
        {
          mime = "application/x-xz";
          run = "ouch";
        }
        {
          url = "*.md";
          run = "piper -- CLICOLOR_FORCE=1 glow -w=$w -s=dark \"$1\"";
        }
        {
          url = "*.csv";
          run = "rich-preview";
        }
        {
          url = "*.rst";
          run = "rich-preview";
        }
        {
          url = "*.ipynb";
          run = "rich-preview";
        }
        {
          url = "*.json";
          run = "rich-preview";
        }
        {
          mime = "application/epub+zip";
          run = "preview-epub";
        }
        {
          url = "*.epub";
          run = "preview-epub";
        }
        {
          url = "*.typ";
          run = "preview-typst";
        }
        {
          url = "**/.git/";
          run = "preview-git";
        }
      ];
      prepend_preloaders = [
        {
          url = "*.typ";
          run = "preview-typst";
        }
      ];
      prepend_fetchers = [
        {
          group = "git";
          url = "*";
          run = "git";
        }
        {
          group = "git";
          url = "*/";
          run = "git";
        }
      ];
    };
  };
}
