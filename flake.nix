{
  outputs = {self, ...}: {
    nixosModules = {
      seaweedfs = import ./nixos-modules/seaweedfs {};
    };
  };
}
