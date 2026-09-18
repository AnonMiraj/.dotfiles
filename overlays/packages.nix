# Package overrides for this host.
final: prev: {
  # These test suites fail in the sandbox (no network); the packages themselves
  # are fine.
  fish = prev.fish.overrideAttrs (_: {doCheck = false;});
  kitty = prev.kitty.overrideAttrs (_: {
    doCheck = false;
    doInstallCheck = false;
  });
}
