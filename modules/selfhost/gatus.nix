{...}: {
  services.gatus = {
    enable = true;
    openFirewall = false;
    settings = {
      web = {
        port = 8099;
        address = "127.0.0.1";
      };
      storage = {
        type = "sqlite";
        path = "/var/lib/gatus/data.db";
      };
      ui = {
        title = "Status | niro";
        description = "Service health monitoring";
      };
    };
  };
}
