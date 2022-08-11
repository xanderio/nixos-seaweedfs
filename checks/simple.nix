{ self
, nixpkgs
, system
,
}:
import (nixpkgs + "/nixos/tests/make-test-python.nix")
  ({ ... }: {
    name = "simple";
    nodes = {
      vm =
        { config
        , pkgs
        , ...
        }: {
          imports = [ self.nixosModules.seaweedfs ];
          services.seaweedfs.master.enable = true;
        };
    };

    testScript = ''
      vm.wait_for_unit("seaweedfs-master")
    '';
  })
{
  inherit system;
  pkgs = import nixpkgs { inherit system; };
}
