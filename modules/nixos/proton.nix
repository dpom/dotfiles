{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-proton.enable = lib.mkEnableOption "Add proton";
  };

  config = lib.mkIf config.dpom-proton.enable {

    environment.systemPackages = with pkgs; [
      protonmail-bridge-gui # Mandatory bridge for Proton
      protonvpn-gui
    ];

    # Activate GNOME Keyring for secure storage of credentials
    services.gnome.gnome-keyring.enable = true;

    # Activate DBus, essential for communication between the application and the keyring
    services.dbus.enable = true;

# Optional, but recommended if you're using a custom DM/WM (e.g., i3, Sway, Hyprland):
    # Make sure the authentication agent starts automatically
    security.polkit.enable = true;

    # systemd.user.services.protonmail-bridge = {
    #   description = "Proton Mail Bridge Daemon";
    #   wantedBy = [ "graphical-session.target" ];
    #   partOf = [ "graphical-session.target" ];
    #   serviceConfig = {
    #     ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive";
    #     Restart = "on-failure";
    #   };
    # };

  };
}
