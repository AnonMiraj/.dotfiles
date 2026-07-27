{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  programs.nvf = {
    enable = true;
    settings.vim = {
      viAlias = true;
      vimAlias = true;
    };
  };
}
