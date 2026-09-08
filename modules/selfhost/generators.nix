{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mapAttrsToList nameValuePair toUpper substring;
  capFirst = s: (substring 0 1 (toUpper s)) + (substring 1 (-1) s);
  displayName = name: svc:
    if svc.homepage.name != null
    then svc.homepage.name
    else capFirst name;
  domainOf = svc: "${svc.domain}.niro.lan";
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
  cert = "${config.my.caddy.certDir}/${config.my.caddy.certFile}";
  key = "${config.my.caddy.certDir}/${config.my.caddy.keyFile}";
  tlsBlock = ''tls ${cert} ${key}'';
  # Push-status helpers
  svcToList = name: svc: {
    name = displayName name svc;
    group = lib.toLower (groupOf svc);
    port = svc.port;
    urlPath =
      if svc.gatus.checkPath != "/"
      then svc.gatus.checkPath
      else null;
  };
  mkKey = n: g: let
    clean = s: builtins.replaceStrings ["/" "," "." "#" "+" "&" " "] ["-" "-" "-" "-" "-" "-" "-"] s;
  in "${clean g}_${clean n}";
  curlBin = "${pkgs.curl}/bin/curl";
  servicesList = mapAttrsToList svcToList (lib.filterAttrs (_: svc: svc.gatus.enable) config.my.services);
in {
  # ── Caddy vhosts ──────────────────────────────────────────────
  services.caddy = {
    enable = true;
    virtualHosts = let
      generated = mapAttrsToList (name: svc:
        nameValuePair (domainOf svc) {
          serverAliases = ["*.${domainOf svc}"];
          extraConfig = ''
            ${tlsBlock}
            reverse_proxy ${
              if svc.proxyTarget != null
              then svc.proxyTarget
              else "localhost:${toString svc.port}"
            }
          '';
        })
      config.my.services;
      mkVhost = name: vh:
        nameValuePair name {
          serverAliases = vh.serverAliases;
          extraConfig = ''
            ${tlsBlock}
            reverse_proxy ${vh.proxyTarget}
          '';
        };
      extras = [
        (mkVhost "niro.lan" config.my.caddy.extraVhosts."niro.lan")
        (mkVhost "status.niro.lan" config.my.caddy.extraVhosts."status.niro.lan")
        (mkVhost "home.niro.lan" config.my.caddy.extraVhosts."home.niro.lan")
        # Paseo — custom path routing
        (nameValuePair "paseo.niro.lan" {
          serverAliases = config.my.caddy.extraVhosts."paseo.niro.lan".serverAliases;
          extraConfig = ''
            ${tlsBlock}
            handle /ws* { reverse_proxy localhost:6767 }
            handle /api* { reverse_proxy localhost:6767 }
            handle /mcp* { reverse_proxy localhost:6767 }
            handle /public* { reverse_proxy localhost:6767 }
            handle {
              root * /var/lib/paseo/web
              try_files {path} /index.html
              file_server
            }
          '';
        })
        # Aria2 / AriaNg — custom static web + RPC routing
        (nameValuePair "aria.niro.lan" {
          serverAliases = ["*.aria.niro.lan"];
          extraConfig = ''
            ${tlsBlock}
            handle /jsonrpc* {
              reverse_proxy localhost:6800
            }
            handle {
              root * ${pkgs.ariang}/share/ariang
              file_server
            }
          '';
        })
      ];
    in
      builtins.listToAttrs (extras ++ generated);
  };

  # ── Homepage dashboard entries ────────────────────────────────
  services.homepage-dashboard.services = let
    svcList =
      lib.filter (svc: svc.homepage.enable)
      (mapAttrsToList (n: v: v) config.my.services);
    groups = builtins.groupBy (svc: groupOf svc) svcList;
  in
    map (group: {
      "${group}" = map (name: let
        svc = config.my.services.${name};
      in {
        "${displayName name svc}" = {
          href = "https://${domainOf svc}";
          description = descOf svc;
          icon = iconOf svc;
        };
      }) (builtins.attrNames (lib.filterAttrs (_: svc: groupOf svc == group) config.my.services));
    }) (builtins.attrNames groups);

# ── FRP client ────────────────────────────────────────────────
services.frp.instances.frpc = {
    enable = true;
    role = "client";
    settings = {
        serverAddr = "152.53.81.54"; # direct origin IP — Cloudflare doesn't proxy frp :7000
        serverPort = 7000;
        loginFailExit = false;
        proxies = mapAttrsToList (name: svc: {
            inherit name;
            type = "tcp";
            localIP = "127.0.0.1";
            localPort = svc.port;
            remotePort = remotePortOf svc;
        }) (lib.filterAttrs (_: svc: svc.frp.enable) config.my.services);
    };
};

  # ── Gatus endpoints ───────────────────────────────────────────
  services.gatus.settings.endpoints = mapAttrsToList (name: svc: {
    name = displayName name svc;
    group = groupOf svc;
    url = "https://${domainOf svc}${svc.gatus.checkPath}";
    interval = "30s";
    conditions = svc.gatus.conditions;
    client = {insecure = true;};
  }) (lib.filterAttrs (_: svc: svc.gatus.enable) config.my.services);

  # ── Push-status (VPS health push) ─────────────────────────────
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

        ${lib.concatStringsSep "\n" (map (svc: let
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
    wantedBy = ["multi-user.target"];
    timerConfig = {
      OnUnitActiveSec = config.my.pushStatus.interval;
      OnBootSec = config.my.pushStatus.interval;
      RandomizedDelaySec = 30;
    };
  };

  # ── Local hosts resolution for *.niro.lan ─────────────────────
  networking.hosts."127.0.0.1" =
    (mapAttrsToList (_: svc: domainOf svc) config.my.services)
    ++ (builtins.attrNames config.my.caddy.extraVhosts);
}
