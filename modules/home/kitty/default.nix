{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-kitty.enable = lib.mkEnableOption "Add kitty";
  };
  config = lib.mkIf config.dpom-kitty.enable {
    programs.kitty = {
      enable = true;
      shellIntegration.enableBashIntegration = true;
      extraConfig = ''
        scrollback_pager ~/.config/kitty/pager.sh 'INPUT_LINE_NUMBER' 'CURSOR_LINE' 'CURSOR_COLUMN'
        map f1 launch --type overlay --stdin-source=@screen_scrollback ~/.config/kitty/pager.sh
      '';
      keybindings = {
        "kitty_mod+e" = "kitten hints"; # https://sw.kovidgoyal.net/kitty/kittens/hints/
      };
      settings = {
        # https://github.com/kovidgoyal/kitty/issues/371#issuecomment-1095268494
        mouse_map = "left click ungrabbed no-op";
        # Ctrl+Shift+click to open URL.
        confirm_os_window_close = "0";
      };
    };

    home.file.".config/kitty/pager.sh" = {
      source = ./pager.sh;
      executable = true;
    };
  };

}
