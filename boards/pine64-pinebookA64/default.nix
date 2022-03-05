{
  device = {
    manufacturer = "PINE64";
    name = "Pinebook (A64)";
    identifier = "pine64-pinebookA64";
    productPageURL = "https://www.pine64.org/pinebook/";
  };

  hardware = {
    soc = "allwinner-a64";
    mmcBootIndex = "1";
  };

  Tow-Boot = {
    defconfig = "pinebook_defconfig";
  };
}
