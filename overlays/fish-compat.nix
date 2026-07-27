# fish 4.8.0 removed share/fish/tools/create_manpage_completions.py (embedded in binary).
# Extract it so the NixOS fish completion generation still works.
final: prev: {
  fish = prev.fish.overrideAttrs (oa: {
    postInstall = (oa.postInstall or "") + ''
      mkdir -p $out/share/fish/tools
      $out/bin/fish --no-config -c 'status get-file tools/create_manpage_completions.py' \
        > $out/share/fish/tools/create_manpage_completions.py
      chmod +x $out/share/fish/tools/create_manpage_completions.py
    '';
  });
}
