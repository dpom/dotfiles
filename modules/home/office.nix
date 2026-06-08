{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-office.enable =lib.mkEnableOption "Add office programs";
  };

  config = lib.mkIf config.dpom-office.enable {
    home.packages = with pkgs; [
      audacity
      brave
      google-chrome
      libreoffice
      kdePackages.okular
      slack
      vlc
      zoom-us
    ];
  };
}
