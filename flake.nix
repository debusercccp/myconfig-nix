{
  description = "Noya's Declarative NixOS and Dotfiles Flake Configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    nixosConfigurations.lynx = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./hosts/desktop/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.noya = import ./modules/home;
        }
      ];
    };

    homeConfigurations."noya@orion" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [ ./modules/home ];
    };

    devShells.x86_64-linux = {
      default = pkgs.mkShell {
        buildInputs = [ pkgs.rustc pkgs.python3 pkgs.nodejs ];
        shellHook = "echo 'default: Rust, Python, Node'";
      };

      rust = pkgs.mkShell {
        buildInputs = [ pkgs.rustc pkgs.cargo pkgs.rustfmt pkgs.clippy ];
        shellHook = "echo 'Rust shell loaded'";
      };

      python = pkgs.mkShell {
        buildInputs = [ pkgs.python3 ];
        shellHook = "echo 'Python shell loaded'";
      };

      node = pkgs.mkShell {
        buildInputs = [ pkgs.nodejs ];
        shellHook = "echo 'Node shell loaded'";
      };
    };
  };
}
