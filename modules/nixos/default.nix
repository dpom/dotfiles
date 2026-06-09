{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
  
  # Declaring Specific Secrets
  sops.secrets = {
    "password" = {
      owner = "${config.user-vars.user}";
    };
    "email" = {
      owner = "${config.user-vars.user}";
    };
    "github_api_token" = {
      owner = "${config.user-vars.user}";
    };
    "github_personal_token" = {
      owner = "${config.user-vars.user}";
    };
    "gpg_gripkey" = {
      owner = "${config.user-vars.user}";
    };
     "nix_access_token" = {};
  };
  
  imports = [
    inputs.stylix.nixosModules.stylix
    ./cdrom.nix
    ./docker.nix
    ./emacs.nix
    ./email.nix
    ./fonts.nix
    ./nvidia.nix
    ./greetd.nix
    ./podman.nix
    ./proton.nix
    ./solaar.nix
    ./sway.nix
    ./videorec.nix
    ./vpn.nix
    ./xserver.nix
  ];
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    nix.registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  
    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    # nix.nixPath = ["/etc/nix/path"];
    environment.etc =
      lib.mapAttrs'
      (name: value: {
        name = "nix/path/${name}";
        value.source = value.flake;
      })
      config.nix.registry;
  
    nix.settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes ca-derivations";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
    };
  
    nix.extraOptions = ''
      !include ${config.sops.secrets.nix_access_token.path}
      '';
  
    # Set your time zone.
    time.timeZone = config.user-vars.timezone;
  
    # Select internationalisation properties.
    i18n.defaultLocale = config.user-vars.locale;
  
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "ro_RO.UTF-8";
      LC_IDENTIFICATION = "ro_RO.UTF-8";
      LC_MEASUREMENT = "ro_RO.UTF-8";
      LC_MONETARY = "ro_RO.UTF-8";
      LC_NAME = "ro_RO.UTF-8";
      LC_NUMERIC = "ro_RO.UTF-8";
      LC_PAPER = "ro_RO.UTF-8";
      LC_TELEPHONE = "ro_RO.UTF-8";
      LC_TIME = "ro_RO.UTF-8";
      LC_CTYPE="en_US.utf8"; # required by dmenu don't change this
    };
  
   hardware.graphics.enable = true;
  services = {
    # Enable thermal data
    thermald.enable = true;
  
    # Enable fingerprint support
    fprintd.enable = true;
  
    libinput = {
      enable = true;
      touchpad.disableWhileTyping = true;
    };
  
    gvfs.enable = true;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
    devmon.enable = true;
    udisks2.enable = true;
    pcscd.enable = true;
    # Activate gnome-keyring
    gnome.gnome-keyring.enable = true;
    # Disable the SSH agent in GNOME to resolve the conflict
    gnome.gcr-ssh-agent.enable = false;
  };
  # Ensure that secrets can be unlocked at login
  security.pam.services.login.enableGnomeKeyring = true;
    programs = {
      thunar = {
        enable = true;
        plugins = with pkgs.xfce; [ thunar-archive-plugin thunar-volman ];
      };
      dconf.enable = true;
      # This enables the system-wide agent service
      ssh.startAgent = true;
    };
  
    # Force the environment variable to the stable systemd path
    environment.extraInit = ''
    export SSH_AUTH_SOCK="/run/user/$(id -u)/ssh-agent"
  '';
    security = {
      polkit.enable = true;
      rtkit.enable = true;
    };
    # security.pam.services.lightdm.enable = true;
  
    # Activează un agent polkit (necesar pentru pop-up-uri de securitate)
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  
    systemd = {
      sleep.extraConfig = ''
    AllowSuspend=yes
    AllowHibernation=yes
    AllowHybridSleep=yes
    AllowSuspendThenHibernate=yes
  '';
    };
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
    environment.systemPackages = with pkgs; [
          acpi
          age
          git
          htop
          localsend
          mc
          nitrogen
          nixd
          openssh
          pavucontrol
          pasystray
          picom
          pulseaudioFull
          udiskie
          udisks
          unrar
          unzip
          usbutils
          syncthing
          wget
          xcalib
      home-manager
      pinentry-curses
      polkit_gnome
    ];
  
  users.users = {
    "${config.user-vars.user}" = {
      isNormalUser = true;
      extraGroups = [
        "audio"
        "disk"
        "docker"
        "lp"
        "networkmanager"
        "scanner"
        "storage"
        "render"
        "video"
        "wheel"
      ];
    };
  };
  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
    };
  
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 30d";
  };
}
