{
  device = {
    manufacturer = "Orange Pi";
    name = "Zero Plus2 (H5)";
    identifier = "orangePi-zeroPlus2H5";
  };

  hardware = {
    soc = "allwinner-h5";
  };

  Tow-Boot = {
    defconfig = "orangepi_zero_plus2_defconfig";
    patches = [
      ./0001-sun50i-h5-orangepi-zero-plus2-Enable-USB.patch
    ];
  };
}
