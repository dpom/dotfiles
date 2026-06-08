{
  lib,
  pkgs,
  ...
}:
{
  fonts.packages = with pkgs; [
    aporetic
    emacsPackages.all-the-icons-nerd-fonts
  ];
}
