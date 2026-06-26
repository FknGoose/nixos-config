{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "";
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    nixpak = {
      url = "github:nixpak/nixpak";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-mattermost.url = "github:nixos/nixpkgs/dd156a9d4fa76f3b4bb58529f72190226caf0100"; # Due to EOL of team server
    yukigram.url = "github:yukigram/yukigram/release";
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
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
          home-manager = {
            backupFileExtension = "bak";
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs; };
            users.fkngoose = ./home.nix;
          };
        }
      ];
    };

  };
}
