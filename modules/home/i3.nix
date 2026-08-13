{
  config,
  lib,
  pkgs,
  ...
}:
let
  ws1 = "1: emacs";
  ws2 = "2: pers";
  ws3 = "3: term";
  ws4 = "4: work";
  ws5 = "5";
  ws6 = "6";
  ws7 = "7";
  ws8 = "8";
  ws9 = "9";
  ws0 = "0: admin";
in
{
  options = {
    dpom-i3.enable = lib.mkEnableOption "Add i3";
  };

  config = lib.mkIf config.dpom-i3.enable {
    home.packages = (with pkgs; [
      arandr
      autorandr
      blueman
      dex
      dmenu
      feh
      i3
      i3status
      brightnessctl
      maim
      networkmanagerapplet
      playerctl
      pasystray
      papirus-icon-theme
      rofi-power-menu
      xclip
      xdotool
      xsecurelock
      xsel
      thunar
    ]);


    xsession.windowManager.i3 = {
      enable = true;
      package = pkgs.i3;
      config = rec {
        window.border = 1;
        window.titlebar = false;
        
        assigns = {
          "${ws1}" = [{ class = "Emacs"; }];
          "${ws0}" = [{ class = "Slack"; }];
        };
        terminal = "kitty";
        keybindings =
          let
            modifier = "Mod4";
          in lib.mkOptionDefault {
            "${modifier}+Shift+e" = "exec ${pkgs.rofi}/bin/rofi -show p -modi p:${pkgs.rofi-power-menu}/bin/rofi-power-menu";
            "${modifier}+d" = "exec ${pkgs.rofi}/bin/rofi -show-icons -show drun";
            "${modifier}+Shift+c" = "reload";
            "${modifier}+Shift+r" = "restart";
            
            # commands
            "${modifier}+Return" = "exec kitty";
            "${modifier}+f" = "exec ${pkgs.thunar}/bin/thunar";
            
            # switch to workspace
            "${modifier}+1" = "workspace number ${ws1}";
            "${modifier}+2" = "workspace number ${ws2}";
            "${modifier}+3" = "workspace number ${ws3}";
            "${modifier}+4" = "workspace number ${ws4}";
            "${modifier}+5" = "workspace number ${ws5}";
            "${modifier}+6" = "workspace number ${ws6}";
            "${modifier}+7" = "workspace number ${ws7}";
            "${modifier}+8" = "workspace number ${ws8}";
            "${modifier}+9" = "workspace number ${ws9}";
            "${modifier}+0" = "workspace number ${ws0}";
            # switch to workspace
            "${modifier}+Shift+1" = "move container to workspace number ${ws1}";
            "${modifier}+Shift+2" = "move container to workspace number ${ws2}";
            "${modifier}+Shift+3" = "move container to workspace number ${ws3}";
            "${modifier}+Shift+4" = "move container to workspace number ${ws4}";
            "${modifier}+Shift+5" = "move container to workspace number ${ws5}";
            "${modifier}+Shift+6" = "move container to workspace number ${ws6}";
            "${modifier}+Shift+7" = "move container to workspace number ${ws7}";
            "${modifier}+Shift+8" = "move container to workspace number ${ws8}";
            "${modifier}+Shift+9" = "move container to workspace number ${ws9}";
            "${modifier}+Shift+0" = "move container to workspace number ${ws0}";
            # modify layout
            "${modifier}+Shift+m" = "move workspace to output left";
            "${modifier}+Shift+o" = "split h";
            "${modifier}+Shift+v" = "split v";
            
            
            # Clipboard
              "${modifier}+c" = "exec --no-startup-id ${pkgs.rofi}/bin/rofi -modi \"clipboard:${pkgs.haskellPackages.greenclip}/bin/greenclip print\" -show clipboard";

            # Kill app
            "${modifier}+Shift+q" = "kill";

            # Screenshot
            "Print" = "maim --format=png --window $(xdotool getactivewindow) \"$HOME/Pictures/$(date -u +'%Y%m%d-%H%M%SZ')-screenshot.png\"";

            # Volume
            "XF86AudioRaiseVolume" = "exec 'pactl set-sink-volume @DEFAULT_SINK@ +1%' && $refresh_i3status";
            "XF86AudioLowerVolume" = "exec 'pactl set-sink-volume @DEFAULT_SINK@ -1%' && $refresh_i3status";
            "XF86AudioMute" = "exec 'pactl set-sink-mute @DEFAULT_SINK@ toggle' && $refresh_i3status";
          };
        bars = [
          {statusCommand = "${pkgs.i3status}/bin/i3status";
           position = "bottom";
           # trayOutput = "primary";
           fonts = {
             names = ["Aporetic" "DejaVu Sans Mono"];
             style = "Bold";
             size = 14.0;
           };
          }
        ];
        startup = [
          
          {command = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
           always = true;
           notification = false; }
          {command = "${pkgs.pasystray}/bin/pasystray";
           always = true;
           notification = false; }
          {command = "${pkgs.blueman}/bin/blueman-applet";
           always = true;
           notification = false; }
          {command = "exec autorandr -c";
           always = true;
           notification = false; }
          {command = "${pkgs.haskellPackages.greenclip}/bin/greenclip daemon>/dev/null";
           always = true;
           notification = false; }
          {command = "dex --autostart --environment i3";
           always = true;
           notification = false; }
          {command = "${pkgs.feh}/bin/feh --bg-fill ~/casa.jpg";
           always = true;
           notification = false; }
          {command = "emacs --init-directory ~/.config/emacs";
           always = true; }
        ];
      };
    };
  };
}
