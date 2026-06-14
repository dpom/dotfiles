{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-opencode.enable = lib.mkEnableOption "Add opencode agent";
  };
  config = lib.mkIf config.dpom-opencode.enable {
    programs.opencode.enable = true;
  };
}
