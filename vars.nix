{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    user-vars = {
      user = lib.mkOption {
        type = lib.types.str;
        description = "user login";
        default = "dan";
      };
      name = lib.mkOption {
        type = lib.types.str;
        description = "user name";
        default = "Dan Pomohaci";
      };
      home = lib.mkOption {
        type = lib.types.str;
        description = "user home";
        default = "/home/dan";
      };
      locale = lib.mkOption {
        type = lib.types.str;
        description = "user locale";
        default = "en_US.UTF-8";
      };
      timezone = lib.mkOption {
        type = lib.types.str;
        description = "user local timezone";
        default = "Europe/Bucharest";
      };
      proj-root = lib.mkOption {
        type = lib.types.path;
        description = "the configuration project path root";
        # default = /home/dan/.dotfiles;
        default = ./.;
      };
    };
  };
}
