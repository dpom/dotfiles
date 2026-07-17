{ inputs, config, lib, pkgs, outputs, emacsPackage, ... }:
{
  imports = [
    ../../modules/home
  ];

  dpom-ai.enable = true;
  dpom-bash.enable = true;
  dpom-direnv.enable = true;
  dpom-hunspell.enable = true;
  dpom-kanshi.enable = true;
  dpom-kitty.enable = true;
  dpom-office.enable = true;
  dpom-opencode.enable = true;
  dpom-pi.enable = true;
  dpom-rofi.enable = true;
  dpom-sway.enable = true;
  dpom-swaync.enable = true;
  dpom-waybar.enable = true;

  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = [ "graphical-session-pre.target" ];
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "26.05";
}
