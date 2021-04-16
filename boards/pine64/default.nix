{ allwinnerA64, rockchipRK399, fetchpatch }:

{
  pine64-pineA64LTS = allwinnerA64 {
    defconfig = "pine64-lts_defconfig";
    withSPI = true;
    patches = [
      ./0001-configs-pine64-lts-Enable-SPI-flash.patch
    ];
  };
  pine64-pinebookA64 = allwinnerA64 { defconfig = "pinebook_defconfig"; };
  pine64-pinebookPro = rockchipRK399 {
    defconfig = "pinebook-pro-rk3399_defconfig";
    postPatch =
      let
        setup_leds = "led green:power on; led red:standby on";
      in
    ''
      substituteInPlace include/tow-boot_env.h \
        --replace 'setup_leds=\0' 'setup_leds=${setup_leds}\0'
    '';
    patches = [
      ./0001-rk3399-light-pinebook-power-and-standby-leds-during-.patch
      ./0001-rk3399-pinebook-pro-Support-SPI-flash-boot.patch
      (fetchpatch {
        url = "https://patchwork.ozlabs.org/series/232334/mbox/";
        sha256 = "0abmc82dccwmf8fjg7lyxx33r0dfc9h2hrx5d32sjl6mfj88hkj7";
      })
    ];
  };
  pine64-rockpro64 = rockchipRK399 {
    defconfig = "rockpro64-rk3399_defconfig";
    patches = [
      ./0001-rockpro64-rk3399-Configure-SPI-flash-boot-offset.patch
    ];
  };
}
