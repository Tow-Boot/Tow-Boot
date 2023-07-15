{ config, lib, pkgs, ... }:

{
  device = {
    manufacturer = "Libre Computer";
    name = "La Frite";
    identifier = "libreComputer-amlS805xAc";
    productPageURL = "https://libre.computer/products/s805x/";
  };

  hardware = {
    soc = "amlogic-s805x";
    SPISize = 128 /* Mbits */ * 1024 * 1024 / 8; # equiv to 16 MiB
  };

  Tow-Boot = {
    defconfig = "libretech-ac_defconfig";
    config = [
      (lib.mkIf (!config.Tow-Boot.buildUBoot) (helpers: with helpers; {
        # Since this board has no SDIO or SD card slot, the index differs
        # to the defaults set in the Tow-Boot Kconfig.
        TOW_BOOT_MMC0_NAME = freeform ''"eMMC"'';
        TOW_BOOT_MMC1_NAME = freeform ''"(unused)"'';
        TOW_BOOT_MMC2_NAME = freeform ''"(unused)"'';
      }))
    ];
    builder.additionalArguments = {
      FIPDIR = "${pkgs.Tow-Boot.amlogicFirmware}/lafrite";
    };
  };

  documentation.sections.installationInstructions =
    ''
      ## Installation instructions

      This board does not have an SD card slot.

      This makes initial install relatively tricky.

      ### Installing to SPI (recommended)

      For now, this is left undocumented as this requires either doing it from
      an operating system, writing it from the vendor's U-Boot build, or using
      the tethered USB boot protocol.

      In the future, a tethered USB boot install method will be made available.

      ### Installing to shared storage (not supported)

      There is no reason to install to shared storage. This board was designed
      to work with firmware installed to dedicated storage.

      To install, you will need to figure out a way to write the shared disk
      image to the eMMC.
    ''
  ;
}
