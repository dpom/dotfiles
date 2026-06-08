{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-nvidia.enable = lib.mkEnableOption "Add nvidia graphic card";
  };

  config = lib.mkIf config.dpom-nvidia.enable {
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia.open = true; # Set to false for proprietary drivers
  };
}
