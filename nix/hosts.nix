{
  lib,
  inputs,
  self,
  withSystem,
  ...
}: {
  flake.lib.configs = {
    nixos = platform: aspect:
      lib.nixosSystem {
        specialArgs = withSystem platform (
          {
            inputs',
            self',
            ...
          }: {
            inherit inputs inputs' self';
          }
        );
        modules = [
          {nixpkgs.hostPlatform = platform;}
          self.modules.nixos.${aspect}
        ];
      };
    homeManager = platform: aspect:
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.${platform};
        extraSpecialArgs = withSystem platform (
          {
            inputs',
            self',
            ...
          }: {
            inherit inputs inputs' self';
          }
        );
        modules = [
          self.modules.homeManager.${aspect}
        ];
      };
  };
}
