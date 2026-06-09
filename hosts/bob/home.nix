{ inputs, config, lib, pkgs, outputs, ... }:
{
  imports = [
    ../../modules/home
  ];

  # xsession.windowManager.command = "${pkgs.nixgl.auto.nixGLDefault}/bin/nixGL ${config.xsession.windowManager.i3.package}/bin/i3";
  dpom-bash.enable = true;
  dpom-direnv.enable = true;
  dpom-dunst.enable = true;
  dpom-hunspell.enable = true;
  dpom-i3.enable = true;
  dpom-kitty.enable = true;
  dpom-office.enable = true;
  dpom-rofi.enable = true;

  home.packages = with pkgs; [
    calibre
    deluge
    protonvpn-gui
    scribus
    simple-scan
    system-config-printer
  ];

  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = [ "graphical-session-pre.target" ];
    };
  };

  xsession.windowManager.i3.config.terminal = "kitty";

  home.file.".config/i3status/config" = {
    source = ./i3status.config;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.11";
}
