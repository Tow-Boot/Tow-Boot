{
  device = {
    manufacturer = "PINE64";
    name = "A64-LTS";
    identifier = "pine64-pineA64LTS";
    productPageURL = "https://www.pine64.org/devices/single-board-computers/pine-a64-lts/";
    supportLevel = "supported";
  };

  hardware = {
    soc = "allwinner-a64";
    SPISize = 16 * 1024 * 1024; # 16 MiB
  };

  Tow-Boot = {
    defconfig = "pine64-lts_defconfig";
    config = [
      (helpers: with helpers; {
        SPI_FLASH_WINBOND = yes;
      })
    ];
  };
}
