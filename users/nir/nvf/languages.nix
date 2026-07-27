{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  programs.nvf.settings.vim = {
    languages = {
      enableTreesitter = true;
      enableFormat = true;
      nix.enable = true;
      clang.enable = true;
      rust.enable = true;
      python.enable = true;
      markdown.enable = true;
      lua.enable = true;
      bash.enable = true;
      fish.enable = true;
      json.enable = true;
      css.enable = true;
      env.enable = true;
      go.enable = true;
    };
  };
}
