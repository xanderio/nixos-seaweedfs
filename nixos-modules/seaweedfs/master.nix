{ pkgs
, lib
, config
, ...
}:
with lib;

let
  cfg = config.services.seaweedfs.master;

  settingsFormat = pkgs.formats.toml { };
in
{
  options.services.seaweedfs.master =
    let
      makeCliOption = { description, type, ... }@args: mkOption
        args // {
        description = mdDoc description;
        type = types.nullOr type;
        default = null;
      };
    in
    {
      enable = mkEnableOption "seaweed master service";

      cpuprofile = makeCliOption {
        description = "cpu profile output file";
        type = types.path;
      };

      defaultReplication = makeCliOption {
        description = "Default replication type if not specified.";
        type = types.str;
      };

      disableHttp = makeCliOption {
        description = "disable http requests, only gRPC operations are allowed.";
        type = types.bool;
      };

      electionTimeout = makeCliOption {
        description = "election timeout of master servers (default 10s)";
        type = types.str;
      };

      garbageThreshold = makeCliOption {
        description = "threshold to vacuum and reclaim spaces (default 0.3)";
        type = types.float;
      };

      heartbeatInterval = makeCliOption {
        description = "heartbeat interval of master servers, and will be randomly multiplied by [1, 1.25) (default 300ms)";
        type = types.str;
      };

      ip = makeCliOption {
        description = "master <ip>|<server> address, also used as identifier";
        type = types.str;
      };

      "ip.bind" = makeCliOption {
        description = "ip address to bind to. If empty, default to same as -ip option.";
        type = types.str;
      };

      mdir = makeCliOption {
        description = "data directory to store meta data (default " /tmp ")";
        type = types.path;
      };

      memprofile = makeCliOption {
        description = "memory profile output file";
        type = types.path;
      };

      "metrics.address" = makeCliOption {
        description = "Prometheus gateway address <host>:<port>";
        type = types.str;
      };

      "metrics.intervalSeconds" = makeCliOption {
        description = "Prometheus push interval in seconds (default 15)";
        type = types.int;
      };

      metricsPort = makeCliOption {
        description = "Prometheus metrics listen port";
        type = types.port;
      };

      peers = makeCliOption {
        description = "all master nodes in comma separated ip:port list, example: 127.0.0.1:9093,127.0.0.1:9094,127.0.0.1:9095";
        type = types.str;
      };

      port = makeCliOption {
        description = "http listen port (default 9333)";
        type = types.port;
      };

      "port.grpc" = makeCliOption {
        description = "grpc listen port";
        type = types.port;
      };

      raftBootstrap = makeCliOption {
        description = "Whether to bootstrap the Raft cluster";
        type = types.bool;
      };

      raftHashcorp = makeCliOption {
        description = "use hashicorp raft";
        type = types.bool;
      };

      resumeState = makeCliOption {
        description = "resume previous state on start master server";
        type = types.bool;
      };

      volumePreallocate = makeCliOption {
        description = "Preallocate disk space for volumes.";
        type = types.bool;
      };

      volumeSizeLimitMB = makeCliOption {
        description = "Master stops directing writes to oversized volumes.";
        type = types.ints.positive;
      };

      whiteList = makeCliOption {
        description = "comma separated Ip addresses having write permission. No limit if empty.";
        type = types.commas;
      };



      settings = mkOption {
        type = types.submodule {
          freeformType = settingsFormat.type;

          options.master = {
            maintenance = {
              scripts = mkOption {
                description = mdDoc "periodically run these scripts are the same as running them from 'weed shell'";
                type = types.lines;
                default = "";
              };

              sleep_minutes = mkOption {
                description = mdDoc "sleep minutes between each script execution";
                default = 15;
                type = types.int;
              };
            };

            sequencer = {
              type = mkOption {
                description = mdDoc "Choose [raft|snowflake] type for storing the file id sequence";
                default = "raft";
                type = types.enum [ "raft" "snowflake" ];
              };
              sequencer_snowflake_id = mkOption {
                description = mdDoc ''
                  when sequencer.type = snowflake, the snowflake id must be different from other masters.
                  any number between 1~1023
                '';
                type = types.ints.between 0 1023;
                default = 0;
              };
            };

            volume_growth =
              let
                makeCopyOption = default:
                  mkOption {
                    inherit default;
                    type = types.ints.positive;
                    description = mdDoc ''
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

            replication.treat_replication_as_minimums = mkOption {
              default = false;
              type = types.bool;
              description = mdDoc ''
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

  config = mkIf cfg.enable {
    environment.etc."seaweedfs/master.toml".source = settingsFormat.generate "seaweedfs-master.toml" cfg.settings;

    systemd.services.seaweedfs-master =
      let
        masterOptions = filterAttrs (_: v: !(isNull v)) {
          inherit (cfg)
            cpuprofile defaultReplication disableHttp
            electionTimeout garbageThreshold heartbeatInterval
            ip"ip.bind" mdir memprofile"metrics.address"
            "metrics.intervalSeconds" metricsPort peers
            port"port.grpc" raftBootstrap raftHashcorp resumeState
            volumePreallocate volumeSizeLimitMB whiteList;
        };
        optionsFile = pkgs.writeText "seaweedfs-master-options" (generators.toKeyValue { } masterOptions);
      in
      {
        description = "seaweedfs master";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          DynamicUser = mkDefault true;
          PrivateTmp = mkDefault true;
          CacheDirectory = "seaweedfs-master";
          ConfigurationDirectory = "seaweedfs-master";
          RuntimeDirectory = "seaweedfs-master";
          StateDirectory = "seaweedfs-master";
          ExecStart = "${pkgs.seaweedfs}/bin/weed master -options=${optionsFile}";
          LimitNOFILE = mkDefault 65536;
          LimitNPROC = mkDefault 65536;
        };
      };
  };
}
