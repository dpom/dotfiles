{ config, ... }:
{
# Basic SOPS Configuration
  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    age.keyFile = "${config.user-vars.home}/.ssh/id_sops_age";

  };
}
