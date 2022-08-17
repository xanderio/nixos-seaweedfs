{ pkgs, config, lib, ... }:
with lib;

let
  cfg = config.services.seaweedfs.s3;

in
{
  options = {
    services.seaweedfs.s3 = {
      enable = mkEnableOption "seaweedfs s3 server";
    };
  };
  config = mkIf cfg.enable {
    systemd.services.seaweedfs-s3 =
      {
        description = "seaweedfs s3";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          DynamicUser = mkDefault true;
          PrivateTmp = mkDefault true;
          CacheDirectory = "seaweedfs-s3";
          ConfigurationDirectory = "seaweedfs-s3";
          RuntimeDirectory = "seaweedfs-s3";
          StateDirectory = "seaweedfs-s3";
          ExecStart = "${pkgs.seaweedfs}/bin/weed s3";
          LimitNOFILE = mkDefault 65536;
          LimitNPROC = mkDefault 65536;
        };
      };
  };
}
