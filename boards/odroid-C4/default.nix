{ lib, pkgs, ... }:

{
  device = {
    manufacturer = "ODROID";
    name = "C4";
    identifier = "odroid-C4";
    productPageURL = "https://www.hardkernel.com/shop/odroid-c4/";
  };

  hardware = {
    soc = "amlogic-s905x3";
  };

  Tow-Boot = {
    defconfig = "odroid-c4_defconfig";
    config = [
      (helpers: with helpers; {
        USE_PREBOOT = yes;
        PREBOOT = freeform ''"usb start ; usb info"'';
      })
    ];
    builder.additionalArguments = {
      FIPDIR = "${pkgs.Tow-Boot.amlogicFirmware}/odroid-c4";
    };
  };
}
