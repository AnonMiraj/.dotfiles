# Let's Encrypt wildcard certificate for the LAN zone via Cloudflare DNS-01.
#
# `my.lan.domain` is a subdomain of a real Cloudflare-managed zone (default:
# `lab.almiraj.xyz` under `almiraj.xyz`). The certificate is requested with a
# DNS-01 challenge, so no inbound ports are opened and no HTTP server is needed.
# Caddy consumes it through `useACMEHost` for every generated vhost.
#
# The split-brain part lives in modules/selfhost/config.nix: dnsmasq answers
# every `*.${my.lan.domain}` with my.lan.address, so LAN clients never resolve
# the public DNS. The DNS-01 TXT records only ever prove control of the zone.
{config, ...}: let
  domain = config.my.lan.domain;
in {
  # Raw Cloudflare API token. Needs Zone:Zone:Read + Zone:DNS:Edit on
  # `almiraj.xyz` (the zone that contains lab.almiraj.xyz).
  # Stored as a plain secret; rendered into a dotenv template below because
  # lego's EnvironmentFile expects `CLOUDFLARE_DNS_API_TOKEN=...`.
  sops.secrets.cloudflare-dns-api-token = {};

  sops.templates.cloudflare-dns-env = {
    content = ''
      CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder.cloudflare-dns-api-token}
    '';
    # The ACME unit runs as the `acme` system user.
    owner = "acme";
    mode = "0400";
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "ezzibrahimx@gmail.com";
    certs.${domain} = {
      domain = "*.${domain}";
      dnsProvider = "cloudflare";
      environmentFile = config.sops.templates.cloudflare-dns-env.path;
      # Bypass the local split-brain dnsmasq for propagation checks; lego
      # must see the public TXT record, and dnsmasq owns the same zone.
      dnsResolver = "1.1.1.1:53";
      # Caddy runs as its own user; make the cert/key readable by it.
      group = config.services.caddy.group;
      extraDomainNames = [domain];
    };
  };
}
