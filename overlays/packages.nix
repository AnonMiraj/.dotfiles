# Package overrides that do not warrant their own file. The fish workaround
# lives separately in ./fish-compat.nix because it is a version-specific fix.
final: prev: {
  # Test suites are the usual source of "sandbox has no network" failures on
  # this host; the packages themselves are fine.
  kitty = prev.kitty.overrideAttrs (old: {
    doCheck = false;
    doInstallCheck = false;
  });

  # v2rayA needs gVisor for its transparent proxy mode; the nixpkgs build does
  # not enable the tag by default.
  v2raya = prev.v2raya.overrideAttrs (old: {
    tags = ["with_gvisor"];
  });
}
