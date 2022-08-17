{ pkgs, config, lib, ... }:
with lib;

let
  cfg = config.services.seaweedfs.volume;

in
{
  options = {
    services.seaweedfs.volume = {
      enable = mkEnableOption "seaweedfs volume server";

      stores = mkOption {
        default = { };
        type = types.attrsOf (types.submodule {
          options = {
            dir = mkOption {
              type = types.path;
              default = "/tmp";
            };

            diskTag = mkOption {
              type = types.str;
              default = "hdd";
            };

            maxVolumes = mkOption {
              type = types.ints.positive;
              default = 8;
            };
          };
        });
      };
    };
  };
  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (length (builtins.attrNames cfg.stores)) != 0;
        message = ''
          seaweedfs volume server can't be build without at least one configured data store.
          see `services.seaweedfs.volume.stores`
        '';
      }
    ];

    systemd.services.seaweedfs-volume =
      let
        stores = mapAttrs (_: v: concatStringsSep "," (builtins.map builtins.toString v)) (zipAttrs (builtins.attrValues cfg.stores));
        optionsFile = pkgs.writeText "seaweedfs-volume-options" (generators.toKeyValue { } {
          dir = stores.dir;
          max = stores.maxVolumes;
          disk = stores.diskTag;
        });
      in
      {
        description = "seaweedfs volume";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          DynamicUser = mkDefault true;
          PrivateTmp = mkDefault true;
          CacheDirectory = "seaweedfs-volume";
          ConfigurationDirectory = "seaweedfs-volume";
          RuntimeDirectory = "seaweedfs-volume";
          StateDirectory = "seaweedfs-volume";
          ExecStart = "${pkgs.seaweedfs}/bin/weed volume -options=${optionsFile}";
          LimitNOFILE = mkDefault 65536;
          LimitNPROC = mkDefault 65536;
        };
      };
  };
}
