{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , ...
    }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
    in
    flake-utils.lib.eachSystem systems
      (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        checks = import ./checks { inherit self system nixpkgs; };
        packages.seaweedfs = pkgs.callPackage ./pkgs/seaweedfs { };
        formatter = pkgs.nixpkgs-fmt;
      })
    // {
      overlays.default = final: prev: {
        seaweedfs = prev.callPackage ./pkgs/seaweedfs { };
      };
      nixosModules = {
        seaweedfs = import ./nixos-modules/seaweedfs { };
      };
    };
}
