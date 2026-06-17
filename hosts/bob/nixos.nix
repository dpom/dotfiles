{ inputs, config, lib, pkgs, ... }:
{

  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
  ];
  dpom-solaar.enable = true;
  dpom-xserver.enable = true;
  dpom-cdrom.enable = true;
  dpom-proton.enable = true;
    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    # boot.loader.limine.maxGenerations = 10;
    networking = {
      hostName = "bob"; # Define your hostname.
  
      # Enable networking
      networkmanager.enable = true;
      hosts = {
        "192.168.0.100" = [ "bob" "bob.dpom.net" "archie" "archie.dpom.net"];
        "192.168.i0.110" = [ "remarkable"];
      };
      # allow org-roam web ui
      firewall.allowedTCPPorts = [ 35901 ];
  
    };
  
  users.users.git = {
    isNormalUser = true;
    initialPassword = "git";
  };
  services.openssh.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  
  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = with pkgs; [ samsung-unified-linux-driver ];
    defaultShared = true;
  };
  
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.samsung-unified-linux-driver  pkgs.samsung-unified-linux-driver_1_00_37 pkgs.hplipWithPlugin];
  };
  
  
  systemd.tmpfiles.rules = [
    "d ${config.user-vars.home}/syncthing - ${config.user-vars.user} users"
  ];
  
  systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true";
  
  
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = config.user-vars.user;
    group = "users";
    dataDir = config.user-vars.home;    # Default folder for new synced folders, instead of /var/lib/syncthing
    configDir = "${config.user-vars.home}/.config/syncthing";   # Folder for Syncthing's settings and keys
    
  
    settings = {
      options = {
        localAnnouceEnabled = false;
        urAccepted = -1;
      };
      
  
      devices = {
        "mary" = { id = config.user-vars.mary-sync-id; };
        "fram" = { id = config.user-vars.fram-sync-id; };
        "mike" = { id = config.user-vars.mike-sync-id; };
      };
  
      folders = lib.mapAttrs (name: value: {
        label = name;
        path = "${config.user-vars.home}/${value.subPath}";
        devices = [ "mary" ];
      }) {
        "sync" = {
          subPath = "Sync";
          devices = [ "mary" "fram" "mike" ];
        };
        "plan" = { subPath = "pers/plan"; };
        "notes" = { subPath = "pers/notes"; };
        "tutor" = { subPath = "pers/tutor"; };
        "facturi" = { subPath = "pers/facturi"; };
        "pfa" = { subPath = "pers/pfa"; };
        "Maildir" = { subPath = "Maildir"; };
        "work" = { subPath = "work"; };
      };
    };
  };
  
  services.ollama = {
    enable = true;
    package = pkgs.callPackage ../../modules/nixos/ollama.nix {
      inherit (pkgs) ollama;
    };
  
    loadModels = [
      "gemma3:12b"
    ];
  };
  programs.nix-ld.enable = true;
  services.greenclip.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
