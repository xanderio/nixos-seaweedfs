{ self
, nixpkgs
, system
,
}:
import (nixpkgs + "/nixos/tests/make-test-python.nix")
  ({pkgs, ... }: {
    name = "simple";
    nodes = {
      vm =
        { config
        , ...
        }: {
          imports = [ self.nixosModules.seaweedfs ];
	  nixpkgs.overlays = [ self.overlays.default ];
          services.seaweedfs = {
            master.enable = true;
            volume = {
              enable = true;
              stores.tmp = { dir = "/tmp"; };
            };
          };
        };
    };

    testScript = ''
      vm.wait_for_unit("multi-user.target")
      vm.wait_for_unit("seaweedfs-master")
      vm.wait_for_unit("seaweedfs-volume")

      vm.wait_for_open_port(9333)
      vm.log(vm.succeed("curl -o /dev/null http://localhost:9333/cluster/healthz"))
    '';
  })
{
  inherit system;
  pkgs = import nixpkgs { inherit system; };
}
