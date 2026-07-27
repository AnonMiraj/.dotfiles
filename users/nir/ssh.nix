{
  config,
  pkgs,
  ...
}: {
  programs.ssh = {
    enable = true;

    # Silence warning by disabling default config
    enableDefaultConfig = false;

    settings = {
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = "yes";
      };
    };
  };

  services.ssh-agent.enable = true;
}
