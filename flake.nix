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
    flake-utils.lib.eachDefaultSystem
      (system: {
        checks = import ./checks { inherit self system nixpkgs; };
      })
    // {
      nixosModules = {
        seaweedfs = import ./nixos-modules/seaweedfs { };
      };
    };
}
