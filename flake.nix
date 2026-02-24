{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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
      url = "git+https://github.com/end-4/dots-hyprland?submodules=1";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      quickshell,
      agenix,
      nagih7-dots,
      end-4-dots,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;

      # --- HOST DISCOVERY ---
      shouldInclude = name: type: type == "directory" && name != "common";
      hostsDir = ./hosts;
      hostNames = lib.attrNames (lib.filterAttrs shouldInclude (builtins.readDir hostsDir));

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = lib.genAttrs supportedSystems;

      # --- VARIABLE & ARGUMENT HELPERS ---
      getVars =
        hostName:
        let
          systemVars = import ./variables.nix;
          hostVars = import ./hosts/${hostName}/variables.nix;
          system = "${systemVars.isa}-${systemVars.os}";
        in
        {
          inherit system systemVars hostVars;
        };

      getSpecialArgs =
        {
          system,
          systemVars,
          hostVars,
          userObj ? null,
        }:
        let
          unstable-overlay = final: prev: {
            unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
          };
        in
        {
          inherit system;
          overlays = [ unstable-overlay ];
          specialArgs = {
            inherit
              inputs
              quickshell
              systemVars
              hostVars
              nagih7-dots
              end-4-dots
              ;
            inherit userObj;
          };
        };

      # --- BUILDER FUNCTIONS ---
      mkHost =
        hostName:
        let
          vars = getVars hostName;
          args = getSpecialArgs {
            inherit (vars) system systemVars hostVars;
          };
          users = vars.hostVars.users or [ ];
        in
        lib.nixosSystem {
          inherit (args) system specialArgs;
          modules = [
            ./hosts/${hostName}
            agenix.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              nixpkgs.overlays = args.overlays;
              nixpkgs.config.allowUnfree = true;
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = builtins.removeAttrs args.specialArgs [ "userObj" ];
                users = builtins.listToAttrs (
                  map (userObj: {
                    name = userObj.username;
                    value = { ... }: {
                      imports = [ ./home/${userObj.username} ];
                      _module.args.userObj = userObj;
                    };
                  }) users
                );
              };
            }
          ];
        };

      mkHome =
        hostName: userObj:
        let
          vars = getVars hostName;
          args = getSpecialArgs {
            inherit (vars) system systemVars hostVars;
            inherit userObj;
          };

          pkgs = import nixpkgs {
            inherit (args) system;
            config.allowUnfree = true;
            overlays = args.overlays;
          };
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = args.specialArgs;

          modules = [
            ./home/${userObj.username}
          ];
        };

      # --- CONFIG GENERATION LOGIC ---
      homeConfigsList = lib.foldl' (
        acc: hostName:
        let
          vars = getVars hostName;
          users = vars.hostVars.users or [ ];
          userConfigs = builtins.listToAttrs (
            map (userObj: {
              name = userObj.username;
              value = mkHome hostName userObj;
            }) users
          );
        in
        acc // userConfigs
      ) { } hostNames;

    in
    {
      nixosConfigurations = lib.genAttrs hostNames mkHost;
      homeConfigurations = homeConfigsList;

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nixos-rebuild
              home-manager
              git
              just
              sops
            ];
          };
        }
      );
    };
}
