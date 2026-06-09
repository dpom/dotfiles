{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-bash.enable = lib.mkEnableOption "Add bash";
  };

  config = lib.mkIf config.dpom-bash.enable {
    home.packages = (
      with pkgs;
      [
        jump
        neovim
      ]
    );

    programs.bash = {
      enable = true;
      enableCompletion = true;
      initExtra = ''
        eval "$(jump shell)"

        export EDITOR=emacsclient
        export GTAGSLABEL=pygments
        export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
        export TERMINAL=kitty
        export GPG_TTY=$(tty)

        export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
        # export SSH_AUTH_SOCK="/run/user/1000/ssh-agent";
        export ALTERNATE_EDITOR=""

        if [ -z "$SSH_TTY" ] && [ -S "$SSH_AUTH_SOCK" ]; then
            # Încarcă cheia silențios doar dacă socket-ul este valid și disponibil
            ssh-add ~/.ssh/id_ed25519 2>/dev/null
        fi
      '';
    };
    home.file.".local/bin/caps2esc" = {
      text = ''
        setxkbmap -option caps:swapescape
      '';
      executable = true;
    };

    home.file.".local/bin/mynixrun" = {
      text = ''
        #!/usr/bin/env bash

        nix run /home/dan/pers/projects/mynixpkgs#''$1
      '';
      executable = true;
    };

    home.file.".local/bin/mynixinit" = {
      text = ''
        #!/usr/bin/env bash

        nix flake init -t /home/dan/pers/projects/mynixpkgs#''$1
      '';
      executable = true;
    };

  };
}
