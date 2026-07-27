{
  config,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;

    includes = [
      {path = "~/.config/git/config.local";}
    ];

    signing = {
      key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      signByDefault = true;
      format = "ssh";
    };

    settings = {
      user = {
        name = "Anonmiraj";
        email = "ezzibrahimx@gmail.com";
      };

      alias = {
        amend = "commit --amend --no-edit";
        co = "checkout";
        ci = "commit";
        st = "status";
        s = "status -s";
        br = "branch";
        dfs = "diff --staged";
        type = "cat-file -t";
        dump = "cat-file -p";
        last = "log -1 HEAD";
        hist = "log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short";
        lg = "log --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        contributors = "shortlog -n -s";
        remotes = "remote -v";
      };

      core = {
        editor = "nvim";
        autocrlf = false;
        quotePath = false;
        fsmonitor = true;
        untrackedCache = true;
        preloadIndex = true;
      };

      push.default = "simple";
      color.ui = "always";

      color = {
        diff = {
          meta = "yellow bold";
          commit = "cyan bold";
          frag = "magenta bold";
          old = "red bold";
          new = "green bold";
          whitespace = "red reverse";
        };
        "diff-highlight" = {
          oldNormal = "red bold";
          oldHighlight = "red bold 52";
          newNormal = "green bold";
          newHighlight = "green bold 22";
        };
        branch = {
          current = "yellow reverse";
          local = "yellow";
          remote = "green";
        };
        status = {
          added = "green";
          changed = "yellow";
          untracked = "red";
        };
      };

      rerere = {
        enabled = true;
        autoupdate = true;
      };

      rebase = {
        autoStash = true;
        autoSquash = true;
      };

      pull.rebase = false;
      diff.submodule = "log";
      status.submodulesummary = 1;
      init.defaultBranch = "main";
      pager.status = true;

      sendemail = {
        smtpserver = "smtp.gmail.com";
        smtpserverport = 465;
        smtpencryption = "ssl";
        smtpuser = "ezzibrahimx@gmail.com";
      };
    };
  };
}
