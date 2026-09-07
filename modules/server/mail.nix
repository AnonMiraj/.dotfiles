{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.server.mail.enable {
    # G6a — native NixOS mail: postfix + dovecot2 + rspamd + roundcube.
    # Migration: maildir is already dovecot format under
    #   mailcow_vmail-vol-1/_data/<domain>/<user>/Maildir  → copy + doveadm import.
    #
    # TODO(Phase 3): fill in from MIGRATION-BACKUP-INVENTORY.md:
    # - services.postfix: mydestination/mydomain, virtual domains, DKIM via opendkim
    # - services.dovecot2: maildir, passdb (passwd-file/sqlite — no MySQL), sieve
    # - services.rspamd: local + DKIM signing, quarantine
    # - services.roundcube: webmail vhost via Caddy (mail.icpczagazig.org + autodiscover/autoconfig)
    # - DNS: MX (mail.icpczagazig.org), SPF, DKIM, DMARC, PTR — unchanged domains
    # - Caddy tls = auto (LE)
    # - firewall: 25/110/143/465/587/993/995/4190
    # sops secrets below.
    services.postfix.enable = true;

    networking.firewall.allowedTCPPorts = [25 110 143 465 587 993 995 4190];
  };
}