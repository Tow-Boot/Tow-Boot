{
  device = {
    manufacturer = "FriendlyELEC";
    name = "NanoPi M1";
    identifier = "friendlyElec-nanoPiM1";
    productPageURL = "https://wiki.friendlyelec.com/wiki/index.php/NanoPi_M1";
  };

  hardware = {
    soc = "allwinner-h3";
    allwinner.crust.defconfig = "nanopi_m1_defconfig";
  };

  Tow-Boot = {
    defconfig = "nanopi_m1_defconfig";
  };
}
