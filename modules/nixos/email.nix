{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-email.enable = lib.mkEnableOption "Add email";
  };

  config = lib.mkIf config.dpom-email.enable {

    environment.systemPackages = with pkgs; [
      gnupg                 # For password management
      isync                 # Provide the mbsync command
      mu                    # Provide mu and mu4e
      pandoc                # html2text
    ];
  };
}
