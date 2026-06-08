{ config, pkgs, lib, ... }:
{
  options = {
    dpom-dunst.enable = lib.mkEnableOption "Add dunst";
  };
  config = lib.mkIf config.dpom-dunst.enable {
    home.packages = [
      pkgs.libnotify
      pkgs.dunst
    ];
    services = {
      dunst.enable = true;
      dunst.settings = {
        global = {
          monitor = 0;

          # The geometry of the window:
          #   [{width}]x{height}[+/-{x}+/-{y}]
          geometry = "500x10-10+50";

          # font = "Iosevka Comfy 10";

          # The spacing between lines.  If the height is smaller than the
          # font height, it will get raised to the font height.
          line_height = 0;

          # The format of the message.  Possible variables are:
          #   %a  appname
          #   %s  summary
          #   %b  body
          #   %i  iconname (including its path)
          #   %I  iconname (without its path)
          #   %p  progress value if set ([  0%] to [100%]) or nothing
          #   %n  progress value if set without any extra characters
          #   %%  Literal %
          # Markup is allowed
          markup = "full";
          format = "<b>%s</b>\n%b";
          word_wrap = true;

          # Alignment of message text.
          # Possible values are "left", "center" and "right".
          alignment = "left";

          # Show age of message if message is older than show_age_threshold
          # seconds.
          # Set to -1 to disable.
          show_age_threshold = 60;

          # Ignore newlines '\n' in notifications.
          ignore_newline = false;

          # Stack together notifications with the same content
          stack_duplicates = true;

          # Hide the count of stacked notifications with the same content
          hide_duplicate_count = false;

          # Display indicators for URLs (U) and actions (A).
          show_indicators = true;

          # Show how many messages are currently hidden (because of geometry).
          indicate_hidden = true;

          # Shrink window if it's smaller than the width.  Will be ignored if
          # width is 0.
          shrink = false;

          # The transparency of the window.  Range: [0; 100].
          transparency = 10;

          # The height of the entire notification.  If the height is smaller
          # than the font height and padding combined, it will be raised
          # to the font height and padding.
          notification_height = 0;

          # Draw a line of "separator_height" pixel height between two
          # notifications.
          # Set to 0 to disable.
          separator_height = 1;
          # separator_color = "frame";

          # Padding between text and separator.
          padding = 8;

          # Horizontal padding.
          horizontal_padding = 8;

          # Defines width in pixels of frame around the notification window.
          # Set to 0 to disable.
          frame_width = 2;

          # Defines color of the frame around the notification window.
          frame_color = "#89AAEB";

          # Sort messages by urgency.
          sort = true;

          # Don't remove messages, if the user is idle (no mouse or keyboard input)
          # for longer than idle_threshold seconds.
          idle_threshold = 120;

          # Should a notification popped up from history be sticky or timeout
          # as if it would normally do.
          sticky_history = true;

          # Maximum amount of notifications kept in history
          history_length = 20;

          mouse_left_click = "close_current";
          mouse_middle_click = "do_action";
          mouse_right_click = "close_all";

          # Redisplay last message(s).
          # On the US keyboard layout "grave" is normally above TAB and left
          # of "1". Make sure this key actually exists on your keyboard layout,
          # e.g. check output of 'xmodmap -pke'
          history = "ctrl+grave";

          # Context menu.
          context = "ctrl+shift+period";
        };

        urgency_low = {
          # background = "#222222";
          # foreground = "#888888";
          timeout = 10;
        };

        urgency_normal = {
          # background = "#285577";
          # foreground = "#ffffff";
          timeout = 0;
        };

        urgency_critical = {
          # background = lib.mkForce "#900000";
          # foreground = lib.mkForce "#ffffff";
          # frame_color = lib.mkForce "#ff0000";
          timeout = 0;
        };

      };
    };
  };
}
