{
  config,
  lib,
  pkgs,
  ...
}: let
  domain = "almiraj.xyz";
in {
  config = lib.mkIf config.my.server.mail.enable {
    # G6a — native NixOS mail: postfix + dovecot2 + rspamd.
    # PRIMARY domain = almiraj.xyz (user preference). Dovecot Maildirs live at
    # /var/vmail/<domain>/<user>/Maildir (restored from almiraj-wipe-backup).
    # Accounts/aliases are rebuilt from the mailcow DB dump; existing
    # icpczagazig.org addresses can be carried over as an extra vdomain if wanted.
    #
    # Webmail (roundcube) is NOT in this nixpkgs — defer to Phase 3 (add as an
    # OCI container or the nixos-mailserver module) with Caddy fronting it.

    services.postfix = {
      enable = true;
      settings.main = {
        myhostname = "mail.${domain}";
        myorigin = domain;
        mydestination = ["localhost" "localhost.localdomain"];
        # domains we host → virtual mailbox, not local delivery
        virtual_mailbox_domains = domain;
        virtual_mailbox_base = "/var/vmail";
        # delivery via dovecot LMTP
        virtual_transport = "lmtp:unix:private/dovecot-lmtp";
      };
    };

    services.dovecot2 = {
      enable = true;
      enableImap = true;
      enablePop3 = true;
      enableLmtp = true;
      mailUser = "vmail";
      mailGroup = "vmail";
      mailLocation = "maildir:/var/vmail/%d/%n";
      enablePAM = false;
      # passdb/userdb from a passwd-file recreated from the mailcow DB (Phase 3).
    };
    users.users.vmail = {
      isSystemUser = true;
      group = "vmail";
      createHome = true;
      home = "/var/vmail";
      shell = "/run/current-system/sw/bin/nologin";
    };
    users.groups.vmail = {};

    # rspamd: spam + DKIM signing. Key generation + quarantine wired in Phase 3.
    services.rspamd.enable = true;

    # SMTP/IMAP/etc.
    networking.firewall.allowedTCPPorts = [
      25
      110
      143
      465
      587
      993
      995
      4190
    ];
  };
}