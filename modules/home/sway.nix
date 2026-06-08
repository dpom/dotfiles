{
  inputs,
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

  lockCommand = pkgs.swaylock + /bin/swaylock;
in
{
  options = {
    dpom-sway.enable = lib.mkEnableOption "Add sway service";
  };

  config = lib.mkIf config.dpom-sway.enable {
    home.packages = (with pkgs; [
      dex
      dmenu
      grim
      kanshi
      light
      maim
      papirus-icon-theme
      rofi-power-menu
      shotman
      slurp
      swayr
      # swaynotificationcenter
      wdisplays
      wf-recorder
      wl-clipboard
      wofi
      xdotool
      xfce.thunar
      xsecurelock
    ]);

    programs.swaylock = {
      enable = true;
      settings = {
        daemonize = true;
        show-keyboard-layout = true;
        indicator-caps-lock = true;
        indicator-radius = 200;
      };
    };
    

    services.clipman.enable = true;
    wayland.windowManager.sway = {
      enable = true;
      systemd.enable = true;
      config = rec {
        terminal = "kitty";
        window.border = 1;
        window.titlebar = false;
        
        assigns = {
          "${ws1}" = [{ class = "Emacs"; }];
          "${ws0}" = [{ class = "Slack"; }];
        };
        modifier = "Mod4";
        keybindings =
          let
            modifier = config.wayland.windowManager.sway.config.modifier;
          in lib.mkOptionDefault {
              "${modifier}+Shift+e" = "exec ${pkgs.rofi}/bin/rofi -show p -modi p:${pkgs.rofi-power-menu}/bin/rofi-power-menu";
              "${modifier}+d" = "exec ${pkgs.rofi}/bin/rofi -show-icons -show drun";
              "${modifier}+Shift+c" = "reload";
              "${modifier}+Shift+r" = "restart";
            
              # commands
              "${modifier}+Return" = "exec kitty";
              "${modifier}+f" = "exec ${pkgs.xfce.thunar}/bin/thunar";
            
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
            
            

            # Cliboard
            "${modifier}+c" = "exec clipman pick --tool=rofi --tool-args=\"-dmenu -p 'Clipboard' -i -l 10\"";

            # Lock screen
            "${modifier}+Ctrl+l" = "exec ${lockCommand}";

            # Toggle control center
            # "${modifier}+Shift+n" =  "exec swaync-client -t -sw";

            # Screenshot
            "Print" = "exec shotman -c output";
            "Print+Shift" = "exec shotman -c region";
            "Print+Shift+Ctrl" = "exec shotman -c window";

            # Brightness
            "XF86MonBrightnessDown" = "exec ${pkgs.light}/bin/light -U 10";
            "XF86MonBrightnessUp" = "exec ${pkgs.light}/bin/light -A 10";

            # Volume
            "XF86AudioRaiseVolume" = "exec 'pactl set-sink-volume @DEFAULT_SINK@ +1%'";
            "XF86AudioLowerVolume" = "exec 'pactl set-sink-volume @DEFAULT_SINK@ -1%'";
            "XF86AudioMute" = "exec 'pactl set-sink-mute @DEFAULT_SINK@ toggle'";
          };
        startup = [
          {
            command = "swaync";
            always = true;
          }

          {
            command = "nm-applet --indicator";
            always = true;
          }
          {
            command = "${pkgs.waybar}/bin/waybar";
            always = true;
          }
          {
            command = "${pkgs.swayr}/bin/swayrd";
            always = true;
          }
          {
            command = "${pkgs.swaynotificationcenter}/bin/swaync";
            always = true;
          }
          {
            # Start Polkit agent for elevation prompts
            command = "/run/current-system/sw/libexec/polkit-gnome-authentication-agent-1";
            always = true;
          }
          {
            command = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway";
            always = true;
          }
          {
            # command = "~/.nix-profile/bin/emacs --init-directory ~/.config/emacs";
            # command = "emacsclient -c -a \"\"";
            command = "emacs --init-directory ~/.config/emacs";
            always = true;
          }
        ];
        bars = [];
        input = {
          "*" =  { xkb_options = "caps:swapescape"; };
        };
      };
      extraConfig = ''
    # give sway a little time to startup before starting kanshi.
    exec sleep 5; systemctl --user start kanshi.service

    '';
      extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      export _JAVA_AWT_WM_NONREPARENTING=1
      export MOZ_ENABLE_WAYLAND=1
    '';
    };
  };
}
