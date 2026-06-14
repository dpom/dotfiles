{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-gemini.enable = lib.mkEnableOption "Add gemini cli";
  };
  config = lib.mkIf config.dpom-gemini.enable {
    programs.gemini-cli.enable = true;
  };
}
