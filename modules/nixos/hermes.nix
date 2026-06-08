{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-hermes.enable = lib.mkEnableOption "Add hermes";
  };

  config = lib.mkIf config.dpom-hermes.enable {

    services.hermes-agent = {
      enable = true;
      config = {
        model = {
          default = "gemma4";
          provider = "custom";
          base_url = "http://127.0.0.1:11434/v1";
        };
        terminal.backend = "local";

      };
    };
  };
}
