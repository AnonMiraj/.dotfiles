{
  config,
  lib,
  ...
}: {
  options.my.server.cashflow = {
    enable = lib.mkEnableOption "Cash Flow board game (public Caddy vhost on cashflow.almiraj.xyz)";
  };

  config = lib.mkIf config.my.server.cashflow.enable {
    # The game container itself is managed by Docker Compose in
    # /home/dev/poorup (state + .env live there), not by NixOS.
    # This only registers the public vhost via the shared Caddy generator.
    my.publicServices.cashflow = {
      domain = "cashflow.almiraj.xyz";
      port = 3100;
      checkPath = "/api/health";
      group = "games";
    };
  };
}
