{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-xserver.enable = lib.mkEnableOption "Add xserver";
  };

  config = lib.mkIf config.dpom-xserver.enable {
    services.xserver = {
      enable = true;
      windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [
          i3status
        ];
      };
      desktopManager = {
        xterm.enable = false;
      };
      displayManager = {
        lightdm.enable = true;
      };
      xkb = {
        layout = "us";
        options = "caps:swapescape";
      };
    };
    console.useXkbConfig = true;
  };
}
