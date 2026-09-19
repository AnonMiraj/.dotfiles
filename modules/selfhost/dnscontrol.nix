# Sync the public, DNS-only A records for the home `*.lab.almiraj.xyz`
# names with dnscontrol, so phone browsers that bypass dnsmasq (Chrome
# Secure DNS) still reach Niro on the home network.
#
# dnscontrol manages the parent Cloudflare zone; NO_PURGE leaves every
# record that is not listed here untouched. The record list is derived
# from the Niro Caddy vhosts, so it cannot drift from what Caddy serves.
{
  config,
  lib,
  pkgs,
  ...
}: let
  domain = config.my.lan.domain;
  address = config.my.lan.address;

  # `lab.almiraj.xyz` -> `almiraj.xyz` (the actual Cloudflare zone).
  dnsZone = lib.concatStringsSep "." (lib.tail (lib.splitString "." domain));

  labels =
    map (name: lib.removeSuffix ".${dnsZone}" name)
    (lib.attrNames config.services.caddy.virtualHosts);

  records = lib.concatStringsSep ",\n" (
    map (label: ''A("${label}", "${address}", TTL(120))'') labels
  );

  dnsconfig = pkgs.writeText "dnsconfig.js" ''
    var REG_NONE = NewRegistrar("none");
    var DSP_CF = NewDnsProvider("cloudflare");
    DEFAULTS(CF_PROXY_DEFAULT_OFF);
    D("${dnsZone}", REG_NONE, DnsProvider(DSP_CF), NO_PURGE,
    ${records}
    );
  '';

  creds = config.sops.templates."cloudflare-dns-creds.json".path;
in {
  sops.secrets.cloudflare-dns-api-token = {};

  sops.templates."cloudflare-dns-creds.json" = {
    content = ''
      {
        "cloudflare": {
          "TYPE": "CLOUDFLAREAPI",
          "apitoken": "${config.sops.placeholder.cloudflare-dns-api-token}"
        }
      }
    '';
    owner = "root";
    mode = "0400";
  };

  # Kept for `just dns-preview`; the service uses the store path directly.
  environment.etc."dnscontrol/dnsconfig.js".source = dnsconfig;
  environment.systemPackages = [pkgs.dnscontrol];

  systemd.services.cloudflare-dns = {
    description = "Sync lab.almiraj.xyz DNS records via dnscontrol";
    wants = ["network-online.target"];
    after = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/var/lib/cloudflare-dns";
      StateDirectory = "cloudflare-dns";
      Environment = ["HOME=/var/lib/cloudflare-dns"];
      ExecStart = "${lib.getExe pkgs.dnscontrol} push --config ${dnsconfig} --creds ${creds}";
      ProtectHome = true;
      ProtectSystem = "strict";
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };
}
