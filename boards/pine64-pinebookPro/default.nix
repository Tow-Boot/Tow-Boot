{ pkgs, ... }:

{
  device = {
    manufacturer = "PINE64";
    name = "Pinebook Pro";
    identifier = "pine64-pinebookPro";
    productPageURL = "https://www.pine64.org/pinebook-pro/";
    supportLevel = "supported";
  };

  hardware = {
    soc = "rockchip-rk3399";
    SPISize = 16 * 1024 * 1024; # 16 MiB
  };

  Tow-Boot = {
    defconfig = "pinebook-pro-rk3399_defconfig";
    setup_leds = "led green:power on; led red:standby on";
  };
}
