{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    dpom.url = "git+https://github.com/dpom/mynixpkgs";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    solaar = {
      url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz"; # For latest stable version
      #url = "https://flakehub.com/f/Svenum/Solaar-Flake/0.1.1.tar.gz"; # uncomment line for solaar version 1.1.13
      # url = "github:Svenum/Solaar-Flake/main"; # Uncomment line for latest unstable version
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cute-sway-recorder = {
      url = "github:it-is-wednesday/cute-sway-recorder";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };
      nix-hermes.url = "github:0xrsydn/nix-hermes-agent";
  };
  outputs = { self,
              emacs-overlay,
              home-manager,
              nix-hermes,
              nixgl,
              nixpkgs,
              stylix,
              systems,
              sops-nix,
              ... } @ inputs:
    let
      inherit (self) outputs;
          lib = nixpkgs.lib // home-manager.lib;
      forEachSystem = f: lib.genAttrs (import systems) (system: f pkgsFor.${system});
      pkgsFor = lib.genAttrs (import systems) (
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            pulseaudio = true;
          };
          overlays = [
             nixgl.overlay
             emacs-overlay.overlays.default
          ];
        }
      );
    in {
      inherit lib;
      nixosConfigurations = {
        mary = lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
          };
          modules = [
            sops-nix.nixosModules.sops
            ./vars.nix
            ./sops.nix
            ./hosts/mary/nixos.nix
            # nix-ld.nixosModules { programs.nix-ld.dev.enable = true; }
          ];
        };
      };
      homeConfigurations = {
        "dan@mary" = lib.homeManagerConfiguration {
          pkgs = pkgsFor.x86_64-linux;
          extraSpecialArgs = {
            inherit inputs outputs;
          };
          modules = [
            ./vars.nix
            ./sops.nix
            ./hosts/mary/home.nix
          ];
        };
        
      };
    };
}
