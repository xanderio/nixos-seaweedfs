{ self
, nixpkgs
, system
,
}: {
  simple = import ./simple.nix { inherit self nixpkgs system; };
}
