# fish workarounds.
#
# 1. The test suite fails in this sandbox, so it is skipped.
# 2. fish 4.8.0 removed share/fish/tools/create_manpage_completions.py
#    (embedded in the binary). Extract it so the NixOS fish completion
#    generation still works.
final: prev: {
  fish = prev.fish.overrideAttrs (oa: {
    doCheck = false;
    postInstall =
      (oa.postInstall or "")
      + ''
        mkdir -p $out/share/fish/tools
        $out/bin/fish --no-config -c 'status get-file tools/create_manpage_completions.py' \
          > $out/share/fish/tools/create_manpage_completions.py
        chmod +x $out/share/fish/tools/create_manpage_completions.py
      '';
  });
}
