{
  device = {
    manufacturer = "Orange Pi";
    name = "PC 2";
    identifier = "orangePi-pc2";
    productPageURL = "http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-PC-2.html";
  };

  hardware = {
    soc = "allwinner-h5";
    allwinner.crust.defconfig = "orangepi_pc2_defconfig";
  };

  Tow-Boot = {
    defconfig = "orangepi_pc2_defconfig";
  };
}
