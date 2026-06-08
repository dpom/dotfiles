{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-kanshi.enable = lib.mkEnableOption "Add kanshi";
  };

  config = lib.mkIf config.dpom-kanshi.enable {
    services.kanshi = {
      enable = true;
      settings = [
        {
          profile.name = "birou";
          profile.outputs = [
           {
             criteria = "Lenovo Group Limited S24e-20 VNA9F53C";
             position = "0,0";
             scale = 1.0;
             mode = "1920x1080@60.000Hz";
           }
           {
             criteria = "eDP-1";
             position = "1920,0";
             scale = 2.0;
             mode = "2256x1504@59.999Hz";
           }
          ];
        }
        {
          profile.name = "camera elena";
          profile.outputs = [
           {
             criteria = "Philips Consumer Electronics Company PHL 243V7 UK02036031825";
             position = "0,0";
             scale = 1.0;
             mode = "1920x1080@60.000Hz";
           }
           {
             criteria = "eDP-1";
             position = "1920,0";
             scale = 2.0;
             mode = "2256x1504@59.999Hz";
           }
          ];
        }
        {
          profile.name = "laptop";
          profile.outputs = [
            {
              criteria = "eDP-1";
              position = "0,0";
              scale = 2.0;
              mode = "2256x1504@59.999Hz";
            }
          ];
        }
      ];
    };
  };
}
