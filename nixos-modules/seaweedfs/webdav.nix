{ pkgs, config, lib, ... }:
with lib;

let
  cfg = config.services.seaweedfs.webdav;

in
{
  options = {
    services.seaweedfs.webdav = {
      enable = mkEnableOption "seaweedfs webdav server";
    };
  };
  config = mkIf cfg.enable {
    systemd.services.seaweedfs-webdav =
      {
        description = "seaweedfs webdav";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          DynamicUser = mkDefault true;
          PrivateTmp = mkDefault true;
          CacheDirectory = "seaweedfs-webdav";
          ConfigurationDirectory = "seaweedfs-webdav";
          RuntimeDirectory = "seaweedfs-webdav";
          StateDirectory = "seaweedfs-webdav";
          ExecStart = "${pkgs.seaweedfs}/bin/weed webdav";
          LimitNOFILE = mkDefault 65536;
          LimitNPROC = mkDefault 65536;
        };
      };
  };
}
