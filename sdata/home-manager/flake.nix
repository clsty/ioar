# flake.nix
{
  description = "ioar";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
    nixgl.url = "github:nix-community/nixGL";
  };

  outputs = { nixpkgs, home-manager, nixgl, ... }:
    let
      home_attrs = rec {
        username = import ./username.nix;
        homeDirectory = "/home/${username}";
        # Do not edit stateVersion value, see https://github.com/nix-community/home-manager/issues/5794
        stateVersion = "25.05";
      };
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      homeConfigurations = {
        tinydots = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit nixgl home_attrs; };
          modules = [ 
            ./home.nix
          ];
        };
      };
    };
}
