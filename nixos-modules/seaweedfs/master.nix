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
              description = "periodically run these scripts are the same as running them from 'weed shell'";
              type = lib.types.lines;
              default = "";
            };

            sleep_minutes = lib.mkOption {
              description = "sleep minutes between each script execution";
              default = 15;
              type = lib.types.int;
            };
          };

          sequencer = {
            type = lib.mkOption {
              description = "Choose [raft|snowflake] type for storing the file id sequence";
              default = "raft";
              type = lib.types.enum [ "raft" "snowflake" ];
            };
            sequencer_snowflake_id = lib.mkOption {
              description = "when sequencer.type = snowflake, the snowflake id must be different from other masters. any number between 1~1023";
              type = lib.types.int;
              default = 0;
            };
          };

          volume_growth =
            let
              makeCopyOption = default:
                lib.mkOption {
                  inherit default;
                  type = lib.types.int;
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
