{ config, pkgs, ...}: {
  stylix = {
    enable = true;
    polarity = "dark";

    # image = config.lib.stylix.pixel "base0A";
    image = ./casa.jpg;

    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/zenburn.yaml";
    # base16Scheme = {
    #   base00 = "#222524";
    #   base01 = "#ff7a5f";
    #   base02 = "#7fc87f";
    #   base03 = "#e0b02f";
    #   base04 = "#78afff";
    #   base05 = "#fa90ea";
    #   base06 = "#7fcfdf";
    #   base07 = "#cac89f";
    #   base08 = "#5e6160";
    #   base09 = "#ff7a5f";
    #   base0A = "#7fc87f";
    #   base0B = "#e0b02f";
    #   base0C = "#78afff";
    #   base0D = "#fa90ea";
    #   base0E = "#7fcfdf";
    #   base0F = "#eaf2ef";
    # };
    fonts = {
      sizes.terminal = 14;
      sizes.applications = 14;

      monospace = {
        package = pkgs.aporetic;
        name = "Aporetic";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      serif = config.stylix.fonts.sansSerif;
      emoji = config.stylix.fonts.monospace;
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 20;
    };
  };
}
