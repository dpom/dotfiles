{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Script to find the correct path for any sensor name
  findHwmon = pkgs.writeShellScriptBin "find-hwmon" ''
    for d in /sys/class/hwmon/hwmon*; do
      if [ "$(${pkgs.coreutils}/bin/cat $d/name)" = "$1" ]; then
        echo "$d"
        exit 0
      fi
    done
    exit 1
  '';
in
{
  options = {
    dpom-waybar.enable = lib.mkEnableOption "Add waybar";
  };

  config = lib.mkIf config.dpom-waybar.enable {
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "bottom";
          height = 30;
          modules-left = ["sway/workspaces"];
          modules-center = ["sway/window"];
          modules-right = [
            "custom/notification"
            "cpu"
            "memory"
            "disk"
            "battery"
            "custom/cpu-temp"
            "custom/fan"
            "pulseaudio"
            "tray"
            "clock"];

          "sway/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
            # format = "{number} {name} {icon}";
            # format-icons = {
            #   active = "";
            #   # default = "";
            # };
          };

          "tray" = {
            spacing = 5;
            show-passive-items = true;
          };

          "cpu" = {
            format = "  {usage}%";
            tooltip = false;
          };

          "memory" = {
            format = "  {}%";
          };

          "disk" = {
            interval = 30;
            format = "  {percentage_used}%";
            path = "/";
          };

          "battery" = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon}  {capacity}% ";
            format-full = "{icon}  {capacity}%";
            format-charging = " {capacity}%";
            format-plugged = "  {capacity}%";
            format-alt = "{icon}  {time}";
            format-icons = ["" "" "" "" ""];
          };

          # "temperature" = {
          #   hwmon-pathi-abs = "/sys/class/hwmon/hwmon$(find-hwmon cros_ec)";
          #   input-filename = "temp4_input";
          #   critical-threshold = 80;
          #   format = "{icon} {temperatureC}°C";
          #   format-icons = ["" "" ""];
          # };

          "custom/cpu-temp" = {
            interval = 2;
            format = " {}°C";
            exec = pkgs.writeShellScript "get-temp" ''
        # Find the specific temp input that has the label cpu@4c
        LABEL_PATH=$(grep -l "cpu@4c" /sys/class/hwmon/hwmon*/temp*_label | head -n1)
        if [ -n "$LABEL_PATH" ]; then
            # Replace '_label' with '_input' to get the value
            DATA_PATH=''${LABEL_PATH%_label}_input
            RAW=$(cat "$DATA_PATH")
            echo "$((RAW / 1000))"
        else
            echo "N/A"
        fi
    '';
          };

          "custom/fan" = {
            format = " ✲ {} RPM";
            interval = 5;
            exec = pkgs.writeShellScript "get-fan-speed" ''
          EC_PATH=$(${findHwmon}/bin/find-hwmon cros_ec)
          if [ -d "$EC_PATH" ]; then
            cat "$EC_PATH/fan1_input"
          else
            echo "0"
          fi
        '';
            tooltip = false;
          };

          "pulseaudio" = {
            format = "{icon}  {volume}% {format_source}";
            format-bluetooth = "{icon}  {volume}%  {format_source}";
            format-bluetooth-muted = "{icon}!  {format_source}";
            format-muted = " {format_source}";
            format-source = "  {volume}%";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = ["" "" ""];
            };
            on-click = "pavucontrol";
          };

          "custom/notification" = {
            tooltip = false;
            format = "{0} {icon}";
            format-icons = {
              notification = "<span foreground='red'><sup></sup></span>";
              none = "";
              dnd-notification = "<span foreground='red'><sup></sup></span>";
              dnd-none = "";
              inhibited-notification = "<span foreground='red'><sup></sup></span>";
              inhibited-none = "";
              dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
              dnd-inhibited-none = "";
            };
            return-type = "json";
            exec-if = "which swaync-client";
            exec = "swaync-client -swb";
            on-click = "swaync-client -t -sw";
            on-click-right = "swaync-client -d -sw";
            escape = true;
          };


          "custom/hello-from-waybar" = {
            format = "hello {}";
            max-length = 40;
            interval = "once";
            exec = pkgs.writeShellScript "hello-from-waybar" ''
        echo "from within waybar"
      '';
          };

          "clock" = {
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            format-alt = "{:%Y-%m-%d %H:%M}";
            calendar = {
              mode = "year";
              mode-mon-col = 3;
              weeks-pos = "right";
              on-scroll = 1;
              format = {
                months = "<span color='#ffead3'><b>{}</b></span>";
                days = "<span color='#ecc6d9'>{}</span>";
                weeks = "<span color='#99ffdd'>{}</span>";
                weekdays = "<span color='#ffcc66'>{}</span>";
                today = "<span color='#ffee99'><b><u>{}</u></b></span>";
              };
            };
            actions = {
              "on-click-right" = "mode";
              "on-scroll-up" = "shift_up";
              "on-scroll-down" = "shift_down";
            };
          };
        };
      };
      style = ''
#temperature.critical {
  background-color: #E42022;
}
#custom-notification {
  font-family: "NotoSansMono Nerd Font";
}
      '';
    };
  };
}
