{ pkgs, ... }:

{
  device = {
    manufacturer = "PINE64";
    name = "Pinebook Pro";
    identifier = "pine64-pinebookPro";
    productPageURL = "https://www.pine64.org/pinebook-pro/";
  };

  hardware = {
    soc = "rockchip-rk3399";
    SPISize = 16 * 1024 * 1024; # 16 MiB
  };

  Tow-Boot = {
    defconfig = "pinebook-pro-rk3399_defconfig";
    setup_leds = "led green:power on; led red:standby on";
    patches = [
      ./0001-rk3399-light-pinebook-power-and-standby-leds-during-.patch
      ./0001-rk3399-pinebook-pro-Support-SPI-flash-boot.patch
      ./0005-PBP-Fix-Panel-reset.patch

      # phy: rockchip: inno-usb2: fix hang when multiple controllers
      (pkgs.fetchpatch {
        url = "https://patchwork.ozlabs.org/series/237654/mbox/";
        sha256 = "0aiw9zk8w4msd3v8nndhkspjify0yq6a5f0zdy6mhzs0ilq896c3";
      })
    ];

  };
}
