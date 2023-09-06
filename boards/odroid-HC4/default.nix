{ lib, pkgs, ... }:

{
  device = {
    manufacturer = "Hardkernel";
    name = "ODROID-HC4";
    identifier = "odroid-HC4";
    productPageURL = "https://www.hardkernel.com/shop/odroid-hc4/";
  };

  hardware = {
    soc = "amlogic-s905x3";
    SPISize = 16 * 1024 * 1024; # 16 MiB
  };

  Tow-Boot = {
    defconfig = "odroid-hc4_defconfig";
    config = [
      (helpers: with helpers; {
        USE_PREBOOT = yes;
        # 'run boot_pci_enum' is required before 'usb start' to have working USB
        PREBOOT = freeform ''"run boot_pci_enum; usb start ; usb info"'';
      })
    ];
    builder.additionalArguments = {
      FIPDIR = "${pkgs.Tow-Boot.amlogicFirmware}/odroid-hc4";
    };
  };
}
