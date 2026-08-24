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
      "almiraj.xyz" = {
        HostName = "152.53.81.54";
        User = "root";
        proxyCommand = "nc -X 5 -x 127.0.0.1:20170 %h %p";
      };
    };
  };

  services.ssh-agent.enable = true;
}
