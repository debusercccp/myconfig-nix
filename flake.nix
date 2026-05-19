{
  description = "Noya's Declarative NixOS and Dotfiles Flake Configuration";

  inputs = {
    # Canale instabile per avere gli ultimi aggiornamenti di Niri, Neovim e pacchetti di sviluppo
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager sincronizzato con lo stesso canale di nixpkgs
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
      # Deve coincidere esattamente con l'hostname impostato in configuration.nix (lynx)
      lynx = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # 1. Configurazione hardware e di sistema globale
          ./hosts/desktop/configuration.nix

          # 2. Modulo Home Manager integrato a livello di sistema
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            
            # Colleghiamo l'utente "noya" al punto d'ingresso dei moduli utente
            home-manager.users.noya = import ./modules/home;
          }
        ];
      };
    };
  };
}
