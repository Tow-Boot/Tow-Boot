{ lib, pkgs, ... }:

{
  device = {
    manufacturer = "ODROID";
    name = "N2-plus";
    identifier = "odroid-N2-plus";
  };

  hardware = {
    soc = "amlogic-s922x";
    SPISize = 8 * 1024 * 1024;
  };

  Tow-Boot = {
    defconfig = "odroid-n2_defconfig";
    config = [
      (helpers: with helpers; {
        USE_PREBOOT = yes;
        PREBOOT = freeform ''"usb start ; usb info"'';
        CONFIG_DEFAULT_DEVICE_TREE = freeform ''"meson-g12b-odroid-n2-plus"'';
      })
    ];
    patches = [
      # ODROID N2 SPI support
      ./0001-Enable-the-SPI-on-the-ODROID-N2-by-default.patch
    ];
    builder.additionalArguments = {
      FIPDIR = "${pkgs.Tow-Boot.amlogicFirmware}/odroid-n2";
    };
  };
}
