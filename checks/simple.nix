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
          services.seaweedfs = {
            master.enable = true;
            volume = {
              enable = true;
              stores.tmp = { dir = "/tmp"; };
              stores.foo = { dir = "/foo"; };
            };
          };
        };
    };

    testScript = ''
      vm.wait_for_unit("seaweedfs-master")
      vm.wait_for_unit("seaweedfs-volume")
    '';
  })
{
  inherit system;
  pkgs = import nixpkgs { inherit system; };
}
