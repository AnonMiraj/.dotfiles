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
      folder = [
        {
          run = "fish -c 'nvim \"$1\"'";
          block = true;
          desc = "neovim";
          for = "linux";
        }
        {
          run = "kitty --detach nvim \"$@\"";
          orphan = true;
          desc = "neovim (detached)";
          for = "linux";
        }
        {
          run = "fish -c 'lazygit -p \"$1\"'";
          block = true;
          desc = "lazygit";
          for = "linux";
        }
        {
          run = "kitty \"$@\"";
          orphan = true;
          desc = "kitty";
          for = "linux";
        }
        {
          run = "xdg-open \"$@\"";
          orphan = true;
          desc = "xdg-open";
          for = "linux";
        }
      ];
      extract = [
        {
          run = "ouch d -y \"$@\"";
          desc = "Extract here with ouch";
          for = "unix";
        }
      ];
      text = [
        {
          run = "nvim \"$@\"";
          block = true;
          desc = "neovim";
          for = "linux";
        }
        {
          run = "kitty --detach nvim \"$@\"";
          block = true;
          desc = "neovim (detached)";
          for = "linux";
        }
        {
          run = "xdg-open \"$@\"";
          orphan = true;
          desc = "xdg-open";
          for = "linux";
        }
      ];
      document = [
        {
          run = "zathura \"$@\"";
          orphan = true;
          desc = "zathura";
          for = "linux";
        }
        {
          run = "xdg-open \"$@\"";
          orphan = true;
          desc = "xdg-open";
          for = "linux";
        }
        {
          run = "xournalpp \"$@\"";
          orphan = true;
          desc = "xournal++";
          for = "linux";
        }
      ];
      image = [
        {
          run = "xdg-open \"$@\"";
          orphan = true;
          desc = "xdg-open";
          for = "linux";
        }
      ];
      video = [
        {
          run = "mpv \"$@\"";
          orphan = true;
          desc = "mpv";
          for = "linux";
        }
        {
          run = "xdg-open \"$@\"";
          orphan = true;
          desc = "xdg-open";
          for = "linux";
        }
      ];
      audio = [
        {
          run = "mpv \"$@\"";
          orphan = true;
          desc = "mpv";
          for = "linux";
        }
        {
          run = "xdg-open \"$@\"";
          orphan = true;
          desc = "xdg-open";
          for = "linux";
        }
      ];
      fallback = [
        {
          run = "nvim \"$@\"";
          block = true;
          desc = "neovim";
          for = "linux";
        }
        {
          run = "kitty --detach nvim \"$@\"";
          block = true;
          desc = "neovim (detached)";
          for = "linux";
        }
        {
          run = "xdg-open \"$@\"";
          orphan = true;
          desc = "xdg-open";
          for = "linux";
        }
      ];
    };

    open = {
      prepend_rules = [
        {
          mime = "application/pdf";
          use = "document";
        }
        {
          mime = "application/epub+zip";
          use = "document";
        }
        {
          mime = "application/x-mobipocket-ebook";
          use = "document";
        }
      ];
      append_rules = [
        {
          mime = "audio/*";
          use = "audio";
        }
        {
          url = "*";
          use = "fallback";
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
          run = "epub-preview";
        }
        {
          url = "*.epub";
          run = "epub-preview";
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
