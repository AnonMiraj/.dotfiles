{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) yaziPlugins fetchFromGitHub runCommand;

  fromYaziPlugins =
    name:
    runCommand name
      {
        src = fetchFromGitHub {
          owner = "AminurAlam";
          repo = "yazi-plugins";
          rev = "9997d5ba641314a83ed225a73c0293bd013e1bfc";
          hash = "sha256-KDH3Ix8ymqDtxH31NnlVeceaLn8MZy1OSDFLrHbn+IM=";
        };
      }
      ''
        cp -r $src/${name}.yazi $out
      '';

  fetchPlugin =
    {
      pname,
      owner,
      repo,
      rev,
      hash,
    }:
    runCommand pname
      {
        src = fetchFromGitHub {
          inherit owner repo rev;
          hash = hash;
        };
      }
      ''
        cp -r $src $out
      '';
in
{
  programs.yazi.plugins = {
    chmod = yaziPlugins.chmod;
    ouch = yaziPlugins.ouch;
    piper = yaziPlugins.piper;
    "rich-preview" = yaziPlugins."rich-preview";
    "vcs-files" = yaziPlugins."vcs-files";
    "smart-enter" = yaziPlugins.smart-enter;
    "smart-paste" = yaziPlugins.smart-paste;
    # Plugins with setup calls
    git = {
      package = yaziPlugins.git;
      setup = true;
      settings = {
        order = 1500;
      };
    };
    recycle-bin = {
      package = yaziPlugins.recycle-bin;
      setup = true;
    };
    sshfs = {
      package = yaziPlugins.sshfs;
      setup = true;
    };

    spot = {
      package = fromYaziPlugins "spot";
      setup = true;
      settings = {
        metadata_section = {
          enable = true;
          hash_cmd = "xxhsum";
          hash_filesize_limit = 150;
          relative_time = true;
          time_format = "%Y-%m-%d %H:%M";
          show_compression = "size";
        };
        plugins_section = {
          enable = true;
        };
        style = {
          section = "green";
          key = "reset";
          value = "blue";
          colorize_metadata = true;
          height = 20;
          width = 60;
          key_length = 15;
        };
      };
    };
    "spot-video" = {
      package = fromYaziPlugins "spot-video";
    };
    "spot-image" = {
      package = fromYaziPlugins "spot-image";
    };
    "preview-typst" = {
      package = fromYaziPlugins "preview-typst";
    };
    "preview-git" = {
      package = fromYaziPlugins "preview-git";
    };
    "preview-epub" = {
      package = fromYaziPlugins "preview-epub";
    };
    "fchar" = {
      package = fromYaziPlugins "fchar";
    };

    "pref-by-location" = {
      package = fetchPlugin {
        pname = "pref-by-location";
        owner = "boydaihungst";
        repo = "pref-by-location.yazi";
        rev = "0248cfe9737fccfdc11bac485f7a19c440e53e46";
        hash = "sha256-POC/a1DfOsYCctI43611wCqsFxGNu11tfcdFj+Nlx5E=";
      };
      setup = true;
      settings = {
        prefs = [
          {
            location = ".*/Downloads";
            sort = lib.generators.mkLuaInline ''{ "btime", reverse = true, dir_first = true }'';
            linemode = "btime";
          }
          {
            location = "${config.home.homeDirectory}/YouTube";
            sort = lib.generators.mkLuaInline ''{ "btime", reverse = true, dir_first = true }'';
            linemode = "btime";
          }
          {
            location = "/media.*";
            sort = lib.generators.mkLuaInline ''{ "btime", reverse = true, dir_first = true }'';
            linemode = "btime";
          }
        ];
      };
    };

    "what-size" = {
      package = fetchPlugin {
        pname = "what-size";
        owner = "pirafrank";
        repo = "what-size.yazi";
        rev = "ec94d9a8496241d91dcfb2a864214871c326ddc5";
        hash = "sha256-slM9qypEy8A4l3KodE7bmyixA+1c4X7hgoGcQP7R25k=";
      };
    };

    "duck-radar" = {
      package = fetchPlugin {
        pname = "duck-radar";
        owner = "nsavvide";
        repo = "duck-radar.yazi";
        rev = "92d21c1973c819d8903b2566632d22b5e6ec55eb";
        hash = "sha256-P1Uz6PVZMRXzC+nkXsD/7pge0YPfsG8DJ1nVRpG62j8=";
      };
    };

    ucp = {
      package = fetchPlugin {
        pname = "ucp";
        owner = "simla33";
        repo = "ucp.yazi";
        rev = "79043fbbfd39b7b9ae0142d11b315272dd90d33b";
        hash = "sha256-oL3fss8/U6IH2y5B/YdK17h4LvN4XsPypmC+yzJBMnE=";
      };
    };

    "fs-usage" = {
      package = fetchPlugin {
        pname = "fs-usage";
        owner = "walldmtd";
        repo = "fs-usage.yazi";
        rev = "1b420837c66499d5745fb2ea9d06b13e91f2ca3f";
        hash = "sha256-Y33Qi0jQjvNfvbP+6lqTP4f94Wzy8RQJjlMfCoHNM9Y=";
      };
      setup = true;
    };

    "fuzzy-search" = {
      package = fetchPlugin {
        pname = "fuzzy-search";
        owner = "onelocked";
        repo = "fuzzy-search.yazi";
        rev = "7be2437b45be1da9b3be0ed2f244709c9b9be242";
        hash = "sha256-vW6o5vbYXr++cFAcyvl7E2tYHQMV5lGK2rEOG5iiRPg=";
      };
    };

    fr = {
      package = fetchPlugin {
        pname = "fr";
        owner = "lpnh";
        repo = "fr.yazi";
        rev = "aa88cd4d4345c07345275291c1a236343f834c86";
        hash = "sha256-3D1mIQpEDik0ppPQo+/NIhCxEu/XEnJMJ0HiAFxlOE4=";
      };
    };

    "parent-arrow" = {
      package = fetchPlugin {
        pname = "parent-arrow";
        owner = "moxuze";
        repo = "parent-arrow.yazi";
        rev = "1fdb8b491321597c01327505bff46c9bd5bd7044";
        hash = "sha256-AjdUCgWkq6zQ/23qGKLKuCCgM3S6IL1CsS1ZhQWesWo=";
      };
    };
  };
}
