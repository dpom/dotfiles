{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-sway.enable = lib.mkEnableOption "Add sway service";
  };

  config = lib.mkIf config.dpom-sway.enable {
    environment.systemPackages = with pkgs; [
      mako # notification system developed by swaywm maintainer
      shotman
    ];

    # enable sway window manager
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };
    programs.light.enable = true;
    };
  }
