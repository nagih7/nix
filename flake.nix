{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nagih7-dots = {
      url = "git+https://github.com/nagih7/dotfiles?submodules=1";
      flake = false;
    };

    end-4-dots = {
      url = "git+https://github.com/nagih7/hyprland-for-nix?submodules=1&ref=nix";
      flake = false;
    };
    
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, agenix, ... }@inputs:
    let
      lib = nixpkgs.lib;

      mkMachine = hostName: userName:
        let
          systemVars = import ./variables.nix;
          hostVars = import ./hosts/${hostName}/variables.nix;
          system = "${systemVars.isa}-${systemVars.os}";

          userObj = lib.findFirst (u: u.username == userName) 
            (throw "User ${userName} not found in ${hostName}/variables.nix") 
            (hostVars.users or [ ]);

          unstable-overlay = final: prev: {
            unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
          };

          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ unstable-overlay ];
          };

          customArgs = {
            inherit inputs systemVars hostVars hostName userName userObj;
            inherit (inputs) quickshell agenix nagih7-dots end-4-dots zen-browser;
          };

        in {
          nixos = lib.nixosSystem {
            inherit system;
            specialArgs = customArgs;
            modules = [
              ./hosts/${hostName}
              ./modules/nixos/default.nix
              agenix.nixosModules.default
              {
                nixpkgs.overlays = [ unstable-overlay ];
                nixpkgs.config.allowUnfree = true;
              }
            ];
          };

          # --- HOME CONFIGURATION ---
          home = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = customArgs;
            modules = [
              ./home/${userName}/default.nix
              ./modules/home-manager/default.nix
            ];
          };
        };

      desktop = mkMachine "desktop" "nagih";
      laptop  = mkMachine "laptop" "nagih";

    in {
      nixosConfigurations = {
        desktop = desktop.nixos;
        laptop  = laptop.nixos;
      };

      homeConfigurations = {
        "nagih@desktop" = desktop.home;
        "nagih@laptop"  = laptop.home;
      };

      devShells = lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] ( system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = [
              pkgs.nixos-rebuild
              home-manager.packages.${system}.home-manager
              pkgs.just
              pkgs.sops
            ];
          };
        }
      );
    };
}
