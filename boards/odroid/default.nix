{ Tow-Boot, amlogicG12, amlogicFirmware }:

{
  odroid-N2 = amlogicG12 {
    boardIdentifier = "odroid-N2";
    defconfig = "odroid-n2_defconfig";
    FIPDIR = "${amlogicFirmware}/odroid-n2";
    withSPI = true;
    SPISize = 8 * 1024 * 1024;
    patches = [
      # ODROID N2 SPI support
      ./0001-Enable-the-SPI-on-the-ODROID-N2-by-default.patch
    ];
    extraConfig = ''
      CONFIG_USE_PREBOOT=y
      CONFIG_PREBOOT="usb start ; usb info"
      CONFIG_SF_DEFAULT_SPEED=52000000
    '';

  };
  odroid-C2 = Tow-Boot.systems.aarch64.callPackage ./odroid-c2.nix { };
}
