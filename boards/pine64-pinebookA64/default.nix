{
  device = {
    manufacturer = "PINE64";
    name = "A64-LTS";
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
