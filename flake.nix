{
  description = "OpenHands: Code Less, Make More - AI software engineer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # List of supported systems
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      
      # Helper function to generate attributes for all supported systems
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      
      # Helper function to get nixpkgs for a specific system
      nixpkgsFor = system: import nixpkgs { inherit system; };
      
      # Import the OpenHands package definition
      openhandsPackage = system:
        let
          pkgs = nixpkgsFor system;
        in
          import ./nix/package.nix {
            inherit system;
            inherit (pkgs) lib;
            inherit pkgs;
            src = self;
          };
    in {
      # Packages
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor system;
        in {
          default = openhandsPackage system;
          openhands = openhandsPackage system;
        }
      );
      
      # Development shells
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor system;
        in {
          default = import ./nix/devShell.nix {
            inherit system pkgs;
          };
        }
      );
      
      # NixOS module
      nixosModules.default = { config, lib, pkgs, ... }:
        let
          system = pkgs.stdenv.hostPlatform.system or pkgs.system or "x86_64-linux";
          openhandsPkg = self.packages.${system}.openhands;
        in
          import ./nix/nixosModule.nix {
            inherit config lib pkgs;
            openhandsPkg = openhandsPkg;
          };
    };
}