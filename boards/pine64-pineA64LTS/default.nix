{
  device = {
    manufacturer = "PINE64";
    name = "A64-LTS";
    identifier = "pine64-pineA64LTS";
  };

  hardware = {
    soc = "allwinner-a64";
    SPISize = 16 * 1024 * 1024; # 16 MiB
  };

  Tow-Boot = {
    defconfig = "pine64-lts_defconfig";
    patches = [
      ./0001-configs-pine64-lts-Enable-SPI-flash.patch
    ];
  };
}
