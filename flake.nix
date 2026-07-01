{
  description = "NixOS server for MomentoCero deployment";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.darwin.follows = "";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { nixpkgs, nixpkgs-unstable, disko, agenix, ... }@inputs: {
    nixosConfigurations.momentocero = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
      };
      modules = [
        agenix.nixosModules.default
        disko.nixosModules.disko
        ./configuration.nix
        ./hardware-configuration.nix
      ];
    };
  };
}
