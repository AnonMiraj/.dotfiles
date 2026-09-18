# Homepage dashboard entries, grouped by my.services.<name>.homepage.group.
{
  config,
  lib,
  ...
}: let
  h = import ../../lib/selfhost.nix {inherit lib config;};
  inherit (h) descOf displayName domainOf groupOf iconOf;

  enabledNames =
    builtins.attrNames
    (lib.filterAttrs (_: svc: svc.homepage.enable) config.my.services);
  groups = builtins.groupBy (name: groupOf config.my.services.${name}) enabledNames;
in {
  services.homepage-dashboard.services =
    map (group: {
      "${group}" =
        map (name: let
          svc = config.my.services.${name};
        in {
          "${displayName name svc}" = {
            href = "https://${domainOf svc}";
            description = descOf svc;
            icon = iconOf svc;
          };
        })
        groups.${group};
    })
    (builtins.attrNames groups);
}
