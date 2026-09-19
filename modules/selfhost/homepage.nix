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

  # Public VPS services are listed as a separate Homepage group so the
  # dashboard at https://lab.almiraj.xyz covers both hosts.
  vpsServices =
    lib.mapAttrsToList (key: svc: {
      "${
        if svc.name != null
        then svc.name
        else key
      }" = {
        href =
          if svc.href != null
          then svc.href
          else "https://${svc.domain}";
        description =
          if svc.description != null
          then svc.description
          else "";
        icon =
          if svc.icon != null
          then svc.icon
          else "https://www.google.com/s2/favicons?domain=${svc.domain}&sz=64";
      };
    })
    config.my.publicDashboard;
in {
  services.homepage-dashboard.services =
    (map (group: {
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
      (builtins.attrNames groups))
    ++ [{"VPS" = vpsServices;}];
}
