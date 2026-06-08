{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-rofi.enable = lib.mkEnableOption "Add rofi";
  };

  config = lib.mkIf config.dpom-rofi.enable {
    programs.rofi = {
      enable = true;
      plugins = with pkgs; [rofi-power-menu ];
      font = lib.mkForce "Aporetic 16";
      extraConfig = {
        modi = "window,drun,ssh,combi";
        combi-modi = "window,drun,ssh";
        icon-theme = "Papirus";
        theme-str = "window {width: 8em;} listview {lines: 6;}";
      };
    };
  };
}
