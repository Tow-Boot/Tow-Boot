{ Tow-Boot, rockchipRK399, fetchpatch }:

{
  kobol-helios64 = rockchipRK399 {
    boardIdentifier = "kobol-helios64";
    defconfig = "helios64-rk3399_defconfig";
    postPatch =
      let
        # Though this will already have been done.
        setup_leds = "led helios64::status on";
      in
    ''
      substituteInPlace include/tow-boot_env.h \
        --replace 'setup_leds=\0' 'setup_leds=${setup_leds}\0'
    '';
    patches = [
      # Use armbian's board enablement.
      # The upstream U-Boot one has less features enabled and working.
      ./0001-helios64-Add-board.patch
      ./0001-helios64-support-SPI-flash-boot.patch
    ];
    withSPI = true;
    SPISize = 128 /* Mbits */ * 1024 * 1024 / 8; # equiv to 16 MiB
  };
}
