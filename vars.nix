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
      bob-sync-id = lib.mkOption {
        type = lib.types.str;
        description = "bob's syncthing id";
        default = "7U5AU3H-PPPCFIK-MUHLV6M-56MFMBB-3GMHKZI-6FJXCO5-J3TGHMY-HWLVCQH";
      };
      mary-sync-id = lib.mkOption {
        type = lib.types.str;
        description = "mary's syncthing id";
        default = "HLFAPO5-KHXLCMR-E25QP7O-NAI6FSJ-EWARVW4-6DLX65H-ERCEFQY-UUFO4QT";
      };
      mike-sync-id = lib.mkOption {
        type = lib.types.str;
        description = "mike's syncthing id";
        default = "FOC2OQP-I5GV2OZ-BYYYZYR-7PKH3DH-RZLYQEC-YGC44JN-3DSHOX5-ZH2ZBA3";
      };
      fram-sync-id = lib.mkOption {
        type = lib.types.str;
        description = "fram's syncthing id";
        default = "GQEWGND-7MINSXB-VXA6H5O-5J2XSOM-HLVGPUB-36YQGQX-VW4Q5CR-DE5YCQ6";
      };

    };
  };
}
