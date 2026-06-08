{
  config,
  pkgs,
  lib,
  ...
}:
{
  options = {
    dpom-direnv.enable = lib.mkEnableOption "Add direnv";
  };
  config = lib.mkIf config.dpom-direnv.enable {
    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv = {
        enable = true;
        # Until https://github.com/nix-community/home-manager/pull/5773
        package = lib.mkIf (config.nix.package != null) (
          pkgs.nix-direnv.override { nix = config.nix.package; }
        );
      };
      config.global = {
        hide_env_diff = true;
      };
    };
  };
}
