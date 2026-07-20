{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{

  imports = [
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    ./hardware-configuration.nix
    ../../modules/nixos
  ];
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # boot.loader.limine.maxGenerations = 10;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  networking = {
    hostName = "mary";
    # Enable networking
    networkmanager.enable = true;
    # Forțează servere DNS statice de încredere
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  
    # Împiedică DHCP-ul wireless să suprascrie DNS-ul local
    networkmanager.dns = "none";
    hosts = {
      "192.168.0.100" = [ "bob" "bob.dpom.net" "archie" "archie.dpom.net"];
      "192.168.0.110" = [ "remarkable"];
    };
    # Optional: Open the  ollama default port if you want to access it from other devices
    firewall.allowedTCPPorts = [ 11434 ];
  };
  
  # dpom-docker.enable = true;
  dpom-greetd.enable = true;
  dpom-solaar.enable = true;
  dpom-sway.enable = true;
  dpom-videorec.enable = true;
  dpom-proton.enable = true;
  dpom-email.enable = true;
  powerManagement = {
    enable = true;
    powertop.enable = true;
    cpuFreqGovernor = lib.mkDefault "ondemand";
  };
  
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Shows battery charge of connected devices on supported
        # Bluetooth adapters. Defaults to 'false'.
        Experimental = true;
        # When enabled other devices can connect faster to us, however
        # the tradeoff is increased power consumption. Defaults to
        # 'false'.
        FastConnectable = true;
      };
      Policy = {
        # Enable all controllers when they are found. This includes
        # adapters present on start as well as adapters that are plugged
        # in later on. Defaults to 'true'.
        AutoEnable = true;
      };
    };
  };
  
  services.thermald.enable = true;
  security.rtkit.enable = true;
  
  environment.systemPackages = with pkgs; [
    framework-tool
    lm_sensors  # Provides 'sensors' command
    fw-ectool   # Framework-specific EC tool
    swtpm # emulare TPM
  ];
  
  services.fprintd.enable = true;
  
  services.udev.extraRules = ''
    # Ethernet expansion card support
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8156", ATTR{power/autosuspend}="20"
    '';
  
  services.libinput.enable = true;
  
  services.pipewire.wireplumber.extraConfig.no-ucm = {
    "monitor.alsa.properties" = {
      "alsa.use-ucm" = false;
    };
  };
  
  services.fwupd.enable = true;
  
  
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
        "bob" = { id = config.user-vars.bob-sync-id; };
        "mike" = { id = config.user-vars.mike-sync-id; };
      };
  
      folders = lib.mapAttrs (name: value: {
        label = name;
        path = "${config.user-vars.home}/${value.subPath}";
        devices = [ "bob" ];
      }) {
        "sync" = { subPath = "Sync"; };
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
  
  hardware.fw-fanctrl = {
    enable = true;
    config = {
      defaultStrategy = "agile";
    };
    disableBatteryTempCheck = false;
  };
  
  dpom-ollama.enable = true;
  dpom-ollama.acceleration = "rocm";
  
  programs.nix-ld.enable = true;
  
  # Activează virtualizarea
  virtualisation.libvirtd.enable = true;
  
  # Instalează programele necesare
  programs.virt-manager.enable = true;
  
  # Adaugă utilizatorul tău în grupul libvirtd pentru a rula fără sudo permanent
  users.users.dan.extraGroups = [ "libvirtd" ];
  
  # Configurează libvirtd să permită emularea TPM
  virtualisation.libvirtd.qemu.runAsRoot = true; # Uneori necesar pentru acces la dispozitivele de securitate

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "26.05";
}
