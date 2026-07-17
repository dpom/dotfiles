{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-ai.enable = lib.mkEnableOption "Add common AI settings";
  };

  config = lib.mkIf config.dpom-ai.enable {
    home.packages = (
      with pkgs;
      [
        lmstudio
        skills
      ]
    );
  };
}
