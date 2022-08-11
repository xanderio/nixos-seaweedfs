{ pkgs
, lib
, config
, ...
}:
let
  cfg = config.services.seaweedfs.master;

  settingsFormat = pkgs.formats.toml { };
in
{
  options.services.seaweedfs.master = {
    enable = lib.mkEnableOption "seaweed master service";

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = settingsFormat.type;

        options.master = {
          maintenance = {
            scripts = lib.mkOption {
              description = lib.mdDoc "periodically run these scripts are the same as running them from 'weed shell'";
              type = lib.types.lines;
              default = "";
            };

            sleep_minutes = lib.mkOption {
              description = lib.mdDoc "sleep minutes between each script execution";
              default = 15;
              type = lib.types.int;
            };
          };

          sequencer = {
            type = lib.mkOption {
              description = lib.mdDoc "Choose [raft|snowflake] type for storing the file id sequence";
              default = "raft";
              type = lib.types.enum [ "raft" "snowflake" ];
            };
            sequencer_snowflake_id = lib.mkOption {
              description = lib.mdDoc ''
                when sequencer.type = snowflake, the snowflake id must be different from other masters.
                any number between 1~1023
              '';
              type = lib.types.ints.between 0 1023;
              default = 0;
            };
          };

          volume_growth =
            let
              makeCopyOption = default:
                lib.mkOption {
                  inherit default;
                  type = lib.types.ints.positive;
                  description = lib.mdDoc ''
                    create this number of logical volumes if no more writable volumes
                    count_x means how many copies of data.
                    e.g.:
                      000 has only one copy, copy_1
                      010 and 001 has two copies, copy_2
                      011 has only 3 copies, copy_3

                    ```
                    copy_1 = 7                # create 1 x 7 = 7 actual volumes
                    copy_2 = 6                # create 2 x 6 = 12 actual volumes
                    copy_3 = 3                # create 3 x 3 = 9 actual volumes
                    copy_other = 1            # create n x 1 = n actual volumes
                    ```
                  '';
                };
            in
            {
              copy_1 = makeCopyOption 7;
              copy_2 = makeCopyOption 6;
              copy_3 = makeCopyOption 3;
              copy_other = makeCopyOption 1;
            };

          replication.treat_replication_as_minimums = lib.mkOption {
            default = false;
            type = lib.types.bool;
            description = lib.mdDoc ''
              any replication counts should be considered minimums. If you specify 010 and
              have 3 different racks, that's still considered writable. Writes will still
              try to replicate to all available volumes. You should only use this option
              if you are doing your own replication or periodic sync of volumes.
            '';
          };
        };
      };
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."seaweedfs/master.toml".source = settingsFormat.generate "seaweedfs-master.toml" cfg.settings;
  };
}
