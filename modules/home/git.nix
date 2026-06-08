{
  config,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    git-filter-repo
  ];

  programs.git = {
    enable = true;
    signing = {
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = true;
    };

    settings = {
      alias = {
        co = "checkout";
        ci = "commit";
        cia = "commit --amend";
        s = "status";
        st = "status";
        b = "branch";
        # p = "pull --rebase";
        pu = "push";
      };
      user = {
        email = config.sops.secrets.email.path;
        name = config.user-vars.name;
        signingKey = "~/.ssh/id_ed25519.pub";
      };
      gpg.format = "ssh";
      tag.gpgsign = true;
      commit.gpgsign = true;
      # Această setare este utilă pentru a evita erorile pe unele versiuni de Git
      "gpg \"ssh\"" = {
        program = "${pkgs.openssh}/bin/ssh-keygen";
        allowedSignersFile = "~/.ssh/allowed-signatures";
      };

      init.defaultBranch = "master"; # Undo breakage due to https://srid.ca/luxury-belief
      core.editor = "emacsclient";
      #protocol.keybase.allow = "always";
      pull.rebase = "false";
      github.user = "dpom";
    };
    iniContent = {
      # Branch with most recent change comes first
      branch.sort = "-committerdate";
      # Remember and auto-resolve merge conflicts
      # https://git-scm.com/book/en/v2/Git-Tools-Rerere
      rerere.enabled = true;
    };
    ignores = [ "*~" "*.swp" ];
    lfs.enable = true;
  };

  programs.lazygit = {
    enable = true;
    settings = {
      # This looks better with the kitty theme.
      gui.theme = {
        lightTheme = false;
        activeBorderColor = [ "white" "bold" ];
        inactiveBorderColor = [ "white" ];
        selectedLineBgColor = [ "reverse" "white" ];
      };
    };
  };
}
