{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixos-hardware, home-manager, ... }: {
    nixosConfigurations.nixos-x390 = nixpkgs.lib.nixosSystem {
    	modules = [
			./configuration.nix
    		nixos-hardware.nixosModules.lenovo-thinkpad-x390
    		home-manager.nixosModules.home-manager
    		{
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.fkngoose = ./home.nix;
    		}
    	];
    };

  };
}
