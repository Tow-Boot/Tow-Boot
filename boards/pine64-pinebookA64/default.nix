{
  device = {
    manufacturer = "PINE64";
    name = "Pinebook (A64)";
    identifier = "pine64-pinebookA64";
  };

  hardware = {
    soc = "allwinner-a64";
    mmcBootIndex = "1";
  };

  Tow-Boot = {
    defconfig = "pinebook_defconfig";
  };
}
