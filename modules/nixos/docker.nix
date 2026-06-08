{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-docker.enable = lib.mkEnableOption "Add docker";
  };

  config = lib.mkIf config.dpom-docker.enable {
    # Enable common container config files in /etc/containers
    virtualisation.containers.enable = true;
    virtualisation = {
      docker = {
        enable = true;
      };
    };

    # Useful other development tools
    environment.systemPackages = with pkgs; [
      dive # look into docker image layers
      docker-compose # start group of containers for dev
    ];
  };
}
