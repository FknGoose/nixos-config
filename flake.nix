{
  description = "A flake.nix for managing configuration.nix and hardware-configuration.nix";

  inputs = {
  
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    
  };

  outputs = { self, nixpkgs, nixos-hardware }: {

    nixosConfigurations.nixos-x390 = nixpkgs.lib.nixosSystem {

    	modules = [
			./configuration.nix
    		nixos-hardware.nixosModules.lenovo-thinkpad-x390
    		
    	];
    };

  };
}
