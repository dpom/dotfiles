{ pkgs, ... }: {
  fonts = {
    fontconfig.enable = true;
    enableDefaultPackages = true;

    packages = with pkgs; [
      aporetic
      fira-code
      fira-code-symbols
      font-awesome
      iosevka
      julia-mono
      liberation_ttf
      nerd-fonts.inconsolata
      nerd-fonts.iosevka-term
      nerd-fonts.terminess-ttf
      noto-fonts
      noto-fonts-color-emoji
      proggyfonts
      source-code-pro
    ];
  };
}
