{
  inputs,
  config,
  pkgs,
  ...
}:
{

  home.packages = with pkgs; [
    alejandra
    aporetic
    babashka
    clj-kondo
    clojure
    clojure-lsp
    cmake
    docker
    docker-buildx
    docker-compose
    fd
    ffmpegthumbnailer
    gcc
    gh
    ghostscript
    gnumake
    graphviz
    imagemagick
    just
    libtool
    libxml2
    mediainfo
    msmtp
    neil
    nixd
    nixfmt-rfc-style
    nodePackages.graphql-language-service-cli
    nodejs_24
    pandoc
    plantuml
    poppler
    ripgrep
    sops
    source-code-pro
    sqls
    temurin-bin
    texliveFull
    tree-sitter
    treefmt
    unzip
    uv
    yaml-language-server
    yq
  ];

  programs.emacs = {
    enable = true;
    package = (pkgs.emacs-pgtk.override {
      withNativeCompilation = true;
      withTreeSitter = true;
    });
  extraPackages = epkgs: [
      epkgs.clojure-ts-mode
      epkgs.erk
      epkgs.mu4e
      epkgs.pdf-tools
      epkgs.treesit-grammars.with-all-grammars
      epkgs.vterm
    ];
  };

  # Daemon-ul Systemd pentru pornire instantanee
  # services.emacs = {
  #   enable = true;
  #   defaultEditor = true;
  #   # Această opțiune asigură că daemon-ul pornește după interfața grafică
  #   startWithUserSession = "graphical";
  #   package = config.programs.emacs.finalPackage; # Folosește exact pachetul de mai sus
  # };


  home.file.".config/emacs/early-init.el" = {
    source = ./early-init.el;
  };

  home.file.".config/emacs/init.el" = {
    source = ./init.el;
  };

  home.file.".config/emacs/templates/templates.eld" = {
    source = ./templates/templates.eld;
  };


  home.file.".config/emacs/elisp" = {
    source = ./elisp;
    recursive = true;
  };

  home.file.".local/bin/emacs-dev" = {
    text = ''
#!/usr/bin/env bash

cd ~/.dotfiles/pkgs/emacs

nix run .#emacs-config -- --init-directory=.
'';
    executable = true;
  };

  home.file.".local/bin/emacs-local" = {
    text = ''
#!/usr/bin/env bash

cd ~/.dotfiles/pkgs/emacs

nix run .#emacs-config -- --init-directory=~/.config/emacs
'';
    executable = true;
  };
}
