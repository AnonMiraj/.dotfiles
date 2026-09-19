# Shared derivations for the modules/selfhost/ generator files.
#
# Deliberately kept outside modules/ so that import-tree does not treat it as a
# NixOS module. Import it as:
#
#   let h = import ../../lib/selfhost.nix {inherit lib config;}; in ...
{
  lib,
  config,
}: let
  inherit (lib) substring toUpper replaceStrings;
  domain = config.my.lan.domain;
in rec {
  inherit domain;

  # Name of the security.acme certificate that Caddy should use for every
  # *.domain vhost. The cert itself is declared in modules/selfhost/acme.nix.
  acmeHost = domain;

  capFirst = s: (substring 0 1 (toUpper s)) + (substring 1 (-1) s);

  displayName = name: svc:
    if svc.homepage.name != null
    then svc.homepage.name
    else capFirst name;

  domainOf = svc: "${svc.domain}.${domain}";

  groupOf = svc:
    if svc.homepage.group != null
    then svc.homepage.group
    else "Other";

  descOf = svc:
    if svc.homepage.description != null
    then svc.homepage.description
    else "";

  iconOf = svc:
    if svc.homepage.icon != null
    then svc.homepage.icon
    else "";

  remotePortOf = svc:
    if svc.frp.remotePort != null
    then svc.frp.remotePort
    else svc.port;

  # Gatus external-endpoint keys are "<group>_<name>", with anything awkward
  # inside a URL path or a `grep` pattern replaced by a dash.
  cleanKeyPart = s:
    replaceStrings ["/" "," "." "#" "+" "&" " "] ["-" "-" "-" "-" "-" "-" "-"] s;

  mkKey = name: group: "${cleanKeyPart group}_${cleanKeyPart name}";
}
