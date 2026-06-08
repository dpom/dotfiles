{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-greetd.enable = lib.mkEnableOption "Add greetd";
  };

  config = lib.mkIf config.dpom-greetd.enable {
    services.greetd = {
      enable = true;
      settings = rec {
        #   initial_session = {
        #   command = "${pkgs.sway}/bin/sway";
        #   user = "dan";
        # };
        # default_session = initial_session;
        default_session.command = ''
      ${pkgs.tuigreet}/bin/tuigreet \
        --time \
        --asterisks \
        --user-menu \
        --cmd sway
    '';
      };
    };

    environment.etc."greetd/environments".text = ''
    sway
  '';
  };
}
