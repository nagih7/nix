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
      inputs.home-manager.follows = "home-manager";
    };

    nagih7-dots = {
      url = "git+https://github.com/nagih7/dotfiles?submodules=1";
      flake = false;
    };

    end-4-dots = {
      url = "git+https://github.com/nagih7/hyprland-for-nix?submodules=1&ref=nix";
      flake = false;
    };

    # Local clones (see modules/home-manager/desktop-shell/providers/caelestia)
    # while trying out the caelestia-dots shell before pointing at upstream.
    caelestia-shell = {
      url = "git+file:///home/nagih/Workspaces/config/caelestia-dots";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-dots = {
      url = "git+file:///home/nagih/Workspaces/config/caelestia";
      flake = false;
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-desktop = {
      url = "github:aaddrick/claude-desktop-debian";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      agenix,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;

      systemVars = import ./variables.nix;
      system = "${systemVars.isa}-${systemVars.os}";

      # Every directory under ./hosts (except common/) is a host. Adding a
      # host = adding hosts/<name>/{default,variables,hardware-configuration}.nix.
      hostNames = lib.attrNames (
        lib.filterAttrs (name: type: type == "directory" && name != "common") (builtins.readDir ./hosts)
      );

      # One pkgs shared by NixOS and Home Manager so they can never drift.
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ (import ./overlays { inherit inputs system; }) ];
      };

      mkMachine =
        hostName: userName:
        let
          hostVars = import ./hosts/${hostName}/variables.nix;

          userObj = lib.findFirst (
            u: u.username == userName
          ) (throw "User ${userName} not found in ${hostName}/variables.nix") (hostVars.users or [ ]);

          customArgs = {
            inherit
              inputs
              systemVars
              hostVars
              hostName
              userName
              userObj
              ;
            inherit (inputs)
              quickshell
              agenix
              nagih7-dots
              end-4-dots
              caelestia-shell
              caelestia-dots
              zen-browser
              claude-desktop
              ;
          };
        in
        {
          nixos = lib.nixosSystem {
            inherit system;
            specialArgs = customArgs;
            modules = [
              { nixpkgs.pkgs = pkgs; }
              ./hosts/${hostName}
              ./modules/nixos
              agenix.nixosModules.default
            ];
          };

          home = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = customArgs;
            modules = [
              ./home/${userName}
              ./modules/home-manager
            ];
          };
        };

      machines = lib.genAttrs hostNames (host: mkMachine host "nagih");
    in
    {
      nixosConfigurations = lib.mapAttrs (_: m: m.nixos) machines;

      homeConfigurations = lib.mapAttrs' (host: m: lib.nameValuePair "nagih@${host}" m.home) machines;

      formatter.${system} = pkgs.nixfmt-tree;

      checks.${system} =
        lib.mapAttrs' (
          host: m: lib.nameValuePair "nixos-${host}" m.nixos.config.system.build.toplevel
        ) machines
        // lib.mapAttrs' (host: m: lib.nameValuePair "home-${host}" m.home.activationPackage) machines;

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.nixfmt-tree
          pkgs.nixd
          pkgs.nh
          agenix.packages.${system}.default
          home-manager.packages.${system}.home-manager
        ];
      };
    };
}
