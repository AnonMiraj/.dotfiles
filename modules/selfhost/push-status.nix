# Push local service health to the VPS Gatus instance.
{
  config,
  lib,
  pkgs,
  ...
}: let
  h = import ../../lib/selfhost.nix {inherit lib config;};
  inherit (lib) concatStringsSep filterAttrs mapAttrsToList toLower;
  inherit (h) displayName groupOf mkKey;

  svcToList = name: svc: {
    name = displayName name svc;
    group = toLower (groupOf svc);
    port = svc.port;
    urlPath =
      if svc.gatus.checkPath != "/"
      then svc.gatus.checkPath
      else null;
  };

  curlBin = "${pkgs.curl}/bin/curl";

  servicesList = mapAttrsToList svcToList (filterAttrs (_: svc: svc.gatus.enable) config.my.services);
in {
  systemd.services.push-status = {
    description = "Push local service health to VPS Gatus";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScriptBin "push-status" ''
        set -euo pipefail
        VPS_URL="${config.my.pushStatus.vpsUrl}"
        TOKEN_FILE="${config.my.pushStatus.tokenFile}"

        ${concatStringsSep "\n" (map (svc: let
            key = mkKey svc.name svc.group;
          in ''
            TOKEN=$(grep "^${key}=" "$TOKEN_FILE" | cut -d= -f2 || echo "")
            if [ -z "$TOKEN" ]; then
              echo "Error: Token for ${key} not found in $TOKEN_FILE"
              exit 1
            fi

            HTTP_CODE=$(${curlBin} -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 \
              "http://127.0.0.1:${toString svc.port}${
              if svc.urlPath != null
              then svc.urlPath
              else ""
            }" 2>/dev/null || echo "000")
            if [ "$HTTP_CODE" = "000" ]; then
              ${curlBin} -sf -X POST "$VPS_URL/api/v1/endpoints/${key}/external?success=false&error=connection+failed" \
                -H "Authorization: Bearer $TOKEN" >/dev/null 2>&1 || true
            elif [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]; then
              ${curlBin} -sf -X POST "$VPS_URL/api/v1/endpoints/${key}/external?success=true" \
                -H "Authorization: Bearer $TOKEN" >/dev/null 2>&1 || true
            else
              ${curlBin} -sf -X POST "$VPS_URL/api/v1/endpoints/${key}/external?success=false&error=HTTP+''${HTTP_CODE}" \
                -H "Authorization: Bearer $TOKEN" >/dev/null 2>&1 || true
            fi
          '')
          servicesList)}
      ''}/bin/push-status";
      User = "nir";
      Group = "users";
    };
  };

  systemd.timers.push-status = {
    description = "Push service health every ${config.my.pushStatus.interval}";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnUnitActiveSec = config.my.pushStatus.interval;
      OnBootSec = config.my.pushStatus.interval;
      RandomizedDelaySec = 30;
    };
  };
}
