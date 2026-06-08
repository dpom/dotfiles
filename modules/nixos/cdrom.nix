{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    dpom-cdrom.enable = lib.mkEnableOption "Add cdrom";
  };

  config = lib.mkIf config.dpom-cdrom.enable {
    users.groups.optical = {};

    security.wrappers = {
      cdrecord = {
      owner = "root";
      group = "optical";
      # capabilities = "cap_sys_rawio,cap_ipc_lock=ep";
      setuid = true;
      source = "${pkgs.cdrtools}/bin/cdrecord";
      };

      cdrdao = {
        owner = "root";
        group = "optical";
        setuid = true;
        source = "${pkgs.cdrdao}/bin/cdrdao";
      };
    };

    services.udev.extraRules = ''
  SUBSYSTEM=="scsi_generic", GROUP="optical", MODE="0660"
  SUBSYSTEM=="block", KERNEL=="sr[0-9]*", GROUP="optical", MODE="0660"
'';

#     services.udev.extraRules = ''
#   # Permite grupului optical să acceseze unitatea optică și interfața generică
#   KERNEL=="sr[0-9]*", GROUP="optical", MODE="0660"
#   KERNEL=="sg[0-9]*", GROUP="optical", MODE="0660"
# '';

    environment.systemPackages = with pkgs; [
      kdePackages.k3b
      cdrtools # Offering CD-R discs
      dvdplusrwtools # For DVDs
      vcdimager
      libburn   # An alternative modern K3b can use
    ];
  };
}
