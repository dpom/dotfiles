{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-hunspell.enable = lib.mkEnableOption "Add dictionaries";
  };

  config = lib.mkIf config.dpom-hunspell.enable {
    home.packages = with pkgs; [
      hunspell
      hunspellDicts.en-gb-large
      hunspellDicts.ro-ro
    ];
  };
}
