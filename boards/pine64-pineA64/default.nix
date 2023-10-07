{
  device = {
    manufacturer = "PINE64";
    name = "A64";
    identifier = "pine64-pineA64";
    productPageURL = "https://www.pine64.org/devices/single-board-computers/pine-a64/";
    supportLevel = "best-effort";
  };

  hardware = {
    soc = "allwinner-a64";
  };

  Tow-Boot = {
    defconfig = "pine64_plus_defconfig";
  };
}
