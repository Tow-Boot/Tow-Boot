{ rockchipRK399, fetchpatch }:

rockchipRK399 {
  boardIdentifier = "pine64-pinebookPro";
  defconfig = "pinebook-pro-rk3399_defconfig";
  SPISize = 16 * 1024 * 1024; # 16 MiB
  postPatch =
    let
      setup_leds = "led green:power on; led red:standby on";
    in
  ''
    substituteInPlace include/tow-boot_env.h \
      --replace 'setup_leds=echo\0' 'setup_leds=${setup_leds}\0'
  '';
  patches = [
    ./0001-rk3399-light-pinebook-power-and-standby-leds-during-.patch
    ./0001-rk3399-pinebook-pro-Support-SPI-flash-boot.patch
    ./0001-rk3399-pinebook-pro-Disable-cdn_dp.patch
    ./0005-PBP-Fix-Panel-reset.patch
    (fetchpatch {
      url = "https://patchwork.ozlabs.org/series/237654/mbox/";
      sha256 = "0aiw9zk8w4msd3v8nndhkspjify0yq6a5f0zdy6mhzs0ilq896c3";
    })
  ];
}
