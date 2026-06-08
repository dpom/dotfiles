{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-vpn.enable = lib.mkEnableOption "Add vpn";
  };

  config = lib.mkIf config.dpom-vpn.enable {
    # Activating the daemon service
    services.mullvad-vpn.enable = true;
    # Add the graphical interface package or CLI package
    environment.systemPackages = [ pkgs.mullvad-vpn ];
  };
}
