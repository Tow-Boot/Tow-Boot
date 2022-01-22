{ lib, pkgs, ... }:

{
  device = {
    manufacturer = "ODROID";
    name = "N2";
    identifier = "odroid-N2";
  };

  hardware = {
    soc = "amlogic-s922x";
    SPISize = 8 * 1024 * 1024;
  };

  Tow-Boot = {
    defconfig = "odroid-n2_defconfig";
    patches = [
      # ODROID N2 SPI support
      ./0001-Enable-the-SPI-on-the-ODROID-N2-by-default.patch
    ];
  };

  TEMP = {
    legacyBuilderArguments = {
      FIPDIR = "${pkgs.Tow-Boot.amlogicFirmware}/odroid-n2";
      extraConfig = ''
        CONFIG_USE_PREBOOT=y
        CONFIG_PREBOOT="usb start ; usb info"
      '';
    };
  };
}
