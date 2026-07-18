{
  config,
  inputs,
  lib,
  outputs,
  pkgs,
  ...
}:
{
  # Enable home-manager
  programs.home-manager.enable = true;
  # Autmaticaly expire old home-manager generations (default monthly and 30 days older)
  services.home-manager.autoExpire.enable = true;
  services.home-manager.autoUpgrade.useFlake = true;
  fonts.fontconfig.enable = true;

  # Silence hyprland configType warning (pulled in by stylix)
  wayland.windowManager.hyprland.configType = "hyprlang";

  # Declaring Specific Secrets
  sops.secrets = {
    "github_personal_token" = {};
    "email" = {};
    "nix_access_token" = {};
    "private_dir" = {};
  };
  
  imports = [
    inputs.stylix.homeModules.stylix
    inputs.sops-nix.homeManagerModules.sops
    ./stylix.nix
    ./ai.nix
    ./bash.nix
    ./direnv.nix
    ./dunst.nix
    ./emacs
    ./git.nix
    ./hunspell.nix
    ./i3.nix
    ./kitty
    ./office.nix
    ./pi.nix
    ./rofi.nix
    ./sway.nix
    ./swaync.nix
    ./waybar.nix
    ./kanshi.nix
    ./gemini.nix
    ./opencode.nix
  
  ];
  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
      warn-dirty = false;
    };
    extraOptions = ''
    !include ${config.sops.secrets.nix_access_token.path}
      '';
    };
  home = rec {
    username = config.user-vars.user;
    homeDirectory = "/home/"+username;
    sessionPath = [
      "$HOME/.local/bin"
    ];
    # sessionVariables = {
    #   EDITOR = "emacsclient";
    #   GTAGSLABEL = "pygments";
    #   LOCALE_ARCHIVE = "/usr/lib/locale/locale-archive";
    #   TERMINAL = "kitty";
    # };
  };
  systemd.user.sessionVariables = {
    SSH_AUTH_SOCK = "/run/user/1000/keyring/ssh";
  };
  
  
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "remarkable" = {
        addKeysToAgent = "yes";
        identityFile = "~/.ssh/remarkable2";
      };
      "10.11.99.1" = {
        addKeysToAgent = "yes";
        identityFile = "~/.ssh/remarkable2";
      };
      "*" = {
        forwardAgent = false;
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
        addKeysToAgent = "yes";
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };
  
  programs.keychain = {
    enable = false;
    # keys = [ "id_ed25519" ];
  };
  
  services.ssh-agent.enable = false;
  
  services = {
    ## Enable gpg-agent with ssh support
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      pinentry.package = pkgs.pinentry-gnome3;
      defaultCacheTtl = 28800;   # 8 ore (parola e reținută 8 ore de la ultima utilizare)
      defaultCacheTtlSsh = 28800;
      maxCacheTtl = 86400;       # 24 ore maxim
      maxCacheTtlSsh = 86400;
    };
  
  };
  
  programs = {
    # Gui for OpenPGP
    gpg = {
      ## Enable GnuPG
      enable = true;
      # publicKeys = [ { source = ./.gnupg/privkey.asc; trust = 5; }];
  
      # homedir = "/home/userName/.config/gnupg";
      settings = {
        # Default/trusted key ID (helpful with throw-keyids)
        # Example, you will put your own keyid here
        # Use `gpg --list-keys`
        default-key = config.user-vars.gpg-gripkey;
        trusted-key = config.user-vars.gpg-gripkey;
  
        # https://github.com/drduh/config/blob/master/gpg.conf
        # https://www.gnupg.org/documentation/manuals/gnupg/GPG-Configuration-Options.html
        # https://www.gnupg.org/documentation/manuals/gnupg/GPG-Esoteric-Options.html
        # Some Best Practices, stronger algos etc
        # Use AES256, 192, or 128 as cipher
        personal-cipher-preferences = "AES256 AES192 AES";
        # Use SHA512, 384, or 256 as digest
        personal-digest-preferences = "SHA512 SHA384 SHA256";
        # Use ZLIB, BZIP2, ZIP, or no compression
        personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
        # Default preferences for new keys
        default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
        # SHA512 as digest to sign keys
        cert-digest-algo = "SHA512";
        # SHA512 as digest for symmetric ops
        s2k-digest-algo = "SHA512";
        # AES256 as cipher for symmetric ops
        s2k-cipher-algo = "AES256";
        # UTF-8 support for compatibility
        charset = "utf-8";
        # Show Unix timestamps
        fixed-list-mode = "";
        # No comments in signature
        no-comments = "";
        # No version in signature
        no-emit-version = "";
        # Disable banner
        no-greeting = "";
        # Long hexidecimal key format
        keyid-format = "0xlong";
        # Display UID validity
        list-options = "show-uid-validity";
        verify-options = "show-uid-validity";
        # Display all keys and their fingerprints
        with-fingerprint = "";
        # Cross-certify subkeys are present and valid
        require-cross-certification = "";
        # Disable caching of passphrase for symmetrical ops
        no-symkey-cache = "";
        keyserver =  "hkp://keys.gnupg.net";
        use-agent = true;
        # pinentry-mode = "loopback";
      };
    };
  };
  
  home.packages = with pkgs; [
    git
    gnupg
    haskellPackages.greenclip
    imagemagick
    lzip
    mission-center
    networkmanager-openvpn
    networkmanagerapplet
    openvpn
    pasystray
    sshpass
  ];
  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
  
  services = {
    blueman-applet.enable = true;
    udiskie = {
      enable = true;
      automount = true;
      tray = "always";
    };
    network-manager-applet.enable = true;
  };
  
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true;
      music = "${config.home.homeDirectory}/Media/Music";
      videos = "${config.home.homeDirectory}/Media/Videos";
      pictures = "${config.home.homeDirectory}/Media/Pictures";
      templates = "${config.home.homeDirectory}/Templates";
      download = "${config.home.homeDirectory}/Downloads";
      documents = "${config.home.homeDirectory}/Documents";
      desktop = null;
      publicShare = null;
      extraConfig = {
        DOTFILES = "${config.home.homeDirectory}/.dotfiles";
        PERS = "${config.home.homeDirectory}/pers";
        WORK = "${config.home.homeDirectory}/work";
      };
    };
    mime.enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "brave-browser.desktop";
        "x-scheme-handler/http" = "brave-browser.desktop";
        "x-scheme-handler/https" = "brave-browser.desktop";
        "x-scheme-handler/about" = "brave-browser.desktop";
        "x-scheme-handler/unknown" = "brave-browser.desktop";
      };
      associations.added = {
        "image/svg+xml" = "brave-browser.desktop";
      };
    };
  };
  home.file."./casa.jpg" = {
    source = ./casa.jpg;
  };
  
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [
      exts.pass-otp
      exts.pass-import
      exts.pass-update
    ]);
  };
  
  programs.browserpass = {
    enable = true;
    browsers = [
      "chrome"
      "firefox"
      "brave"
    ];
  };
  programs.mu.enable = true;
  programs.msmtp.enable = true;
  

}
