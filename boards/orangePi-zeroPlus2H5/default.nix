{
  device = {
    manufacturer = "Orange Pi";
    name = "Zero Plus2 (H5)";
    identifier = "orangePi-zeroPlus2H5";
    productPageURL = "http://www.orangepi.org/OrangePiZeroPlus2/";
    supportLevel = "supported";
  };

  hardware = {
    soc = "allwinner-h5";
    mmcBootIndex = "1";
    allwinner.crust.defconfig = "orangepi_zero_plus_defconfig";
  };

  Tow-Boot = {
    defconfig = "orangepi_zero_plus2_defconfig";
  };
}
