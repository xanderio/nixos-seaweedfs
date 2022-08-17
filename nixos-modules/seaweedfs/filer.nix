{ pkgs, config, lib, ... }:
with lib;

let
  cfg = config.services.seaweedfs.filer;

in
{
  options = {
    services.seaweedfs.filer = {
      enable = mkEnableOption "seaweedfs filer server";
    };
  };
  config = mkIf cfg.enable {
    systemd.services.seaweedfs-filer =
      {
        description = "seaweedfs filer";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          DynamicUser = mkDefault true;
          PrivateTmp = mkDefault true;
          CacheDirectory = "seaweedfs-filer";
          ConfigurationDirectory = "seaweedfs-filer";
          RuntimeDirectory = "seaweedfs-filer";
          StateDirectory = "seaweedfs-filer";
          ExecStart = "${pkgs.seaweedfs}/bin/weed filer";
          LimitNOFILE = mkDefault 65536;
          LimitNPROC = mkDefault 65536;
        };
      };
  };
}
