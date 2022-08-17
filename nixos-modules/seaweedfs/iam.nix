{ pkgs, config, lib, ... }:
with lib;

let
  cfg = config.services.seaweedfs.iam;

in
{
  options = {
    services.seaweedfs.iam = {
      enable = mkEnableOption "seaweedfs iam server";
    };
  };
  config = mkIf cfg.enable {
    systemd.services.seaweedfs-iam =
      {
        description = "seaweedfs iam";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          DynamicUser = mkDefault true;
          PrivateTmp = mkDefault true;
          CacheDirectory = "seaweedfs-iam";
          ConfigurationDirectory = "seaweedfs-iam";
          RuntimeDirectory = "seaweedfs-iam";
          StateDirectory = "seaweedfs-iam";
          ExecStart = "${pkgs.seaweedfs}/bin/weed iam";
          LimitNOFILE = mkDefault 65536;
          LimitNPROC = mkDefault 65536;
        };
      };
  };
}
