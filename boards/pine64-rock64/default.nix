{
  device = {
    manufacturer = "PINE64";
    name = "ROCK64";
    identifier = "pine64-rock64";
    productPageURL = "https://www.pine64.org/rock64/";
  };

  hardware = {
    soc = "rockchip-rk3328";
    SPISize = 16 * 1024 * 1024; # 16 MiB
    withDisplay = false;
  };

  Tow-Boot = {
    defconfig = "rock64-rk3328_defconfig";
    patches = [
      ./0001-board-rock64-Enable-booting-from-SPI-flash.patch
      ./0001-ayufan-usb-enablement.patch
    ];
  };
}
