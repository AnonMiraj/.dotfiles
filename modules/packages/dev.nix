{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # Git / GitHub
    lazygit
    diff-so-fancy
    gh

    # Coding agents
    opencode
    tuicr
    claude-code
    inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli

    # Languages & toolchains
    cargo
    rustc
    nodejs
    bun
    uv
    gnumake
    ccache
    clang
    gcc
    zig
    lld
    lldb

    # Language servers
    rust-analyzer
    nil
    tinymist
    lua-language-server
    clang-tools

    # Formatters / linters
    shfmt
    alejandra
    stylua
    golines
    black
    rustfmt
    prettier

    # Lua
    luarocks
    lua5_1
    luajitPackages.magick

    # Nix tooling
    cachix
  ];
}
