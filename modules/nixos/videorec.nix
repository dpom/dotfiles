{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-videorec.enable = lib.mkEnableOption "Add videorecorder";
  };

  config = lib.mkIf config.dpom-videorec.enable {
    programs.gpu-screen-recorder.enable = true; # For promptless recording on both CLI and GUI

    environment.systemPackages = with pkgs; [
      gpu-screen-recorder-gtk # GUI app
    ];
  };
}
