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
          rev = "0fd127f";
          hash = "sha256-AW7PQJ9P6oYZHyH2Vp8CgWGGDy/yhscOl5PWFiv+mqA=";
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
    "fchar" = {
      package = fromYaziPlugins "fchar";
    };

    "pref-by-location" = {
      package = fetchPlugin {
        pname = "pref-by-location";
        owner = "boydaihungst";
        repo = "pref-by-location.yazi";
        rev = "8d355f5";
        hash = "sha256-8LPPU9MGiFOavVMLtMalbbumc+mutLPHdAHX4rxZnfQ=";
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
        rev = "179ebf6";
        hash = "sha256-7q/45TopqbojNRvYDmP9+hgSGPmiyLHBcV051qpOB2Y=";
      };
    };

    "duck-radar" = {
      package = fetchPlugin {
        pname = "duck-radar";
        owner = "nsavvide";
        repo = "duck-radar.yazi";
        rev = "95530e9";
        hash = "sha256-rZcyBvZ4Vl/SoCBgYRB3D0Nro9tMhJIIM2stojck/Zk=";
      };
    };

    ucp = {
      package = fetchPlugin {
        pname = "ucp";
        owner = "simla33";
        repo = "ucp.yazi";
        rev = "a4b5ce1";
        hash = "sha256-jIvooR00smQb8bmS3slj87k4yM9aTeruvhu/1krigZ8=";
      };
    };

    "fs-usage" = {
      package = fetchPlugin {
        pname = "fs-usage";
        owner = "walldmtd";
        repo = "fs-usage.yazi";
        rev = "4f4992b";
        hash = "sha256-GsvFylogF2GU2i/aGwE1ML2ePcFlW2C4VLS44Cj9xf4=";
      };
      setup = true;
    };

    "fuzzy-search" = {
      package = fetchPlugin {
        pname = "fuzzy-search";
        owner = "onelocked";
        repo = "fuzzy-search.yazi";
        rev = "main";
        hash = "sha256-vW6o5vbYXr++cFAcyvl7E2tYHQMV5lGK2rEOG5iiRPg=";
      };
    };

    fr = {
      package = fetchPlugin {
        pname = "fr";
        owner = "lpnh";
        repo = "fr.yazi";
        rev = "main";
        hash = "sha256-3D1mIQpEDik0ppPQo+/NIhCxEu/XEnJMJ0HiAFxlOE4=";
      };
    };

    "parent-arrow" = {
      package = fetchPlugin {
        pname = "parent-arrow";
        owner = "moxuze";
        repo = "parent-arrow.yazi";
        rev = "main";
        hash = "sha256-AjdUCgWkq6zQ/23qGKLKuCCgM3S6IL1CsS1ZhQWesWo=";
      };
    };
  };
}
