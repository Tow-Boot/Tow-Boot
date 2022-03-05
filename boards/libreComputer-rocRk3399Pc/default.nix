{ lib, ... }:

{
  device = {
    manufacturer = "Libre Computer";
    name = "Renegade Elite";
    identifier = lib.mkDefault "libreComputer-rocRk3399Pc";
    productPageURL = "https://libre.computer/products/rk3399/";
  };

  hardware = {
    soc = "rockchip-rk3399";
    SPISize = 16 * 1024 * 1024; # 16 MiB
  };

  Tow-Boot = {
    defconfig = lib.mkDefault "roc-pc-rk3399_defconfig";
    setup_leds = "led green:work on; led red:diy on";
    patches = [
      ./0001-rk3399-roc-pc-Configure-SPI-flash-boot-offset.patch
      ./roc-pc-config.patch
    ];
  };
}
