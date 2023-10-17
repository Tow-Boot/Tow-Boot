{
  device = {
    manufacturer = "FriendlyELEC";
    name = "NanoPi M1 Plus";
    identifier = "friendlyElec-nanoPiM1Plus";
    productPageURL = "https://www.friendlyelec.com/index.php?route=product/product&path=69&product_id=176";
    supportLevel = "best-effort";
  };

  hardware = {
    soc = "allwinner-h3";
    allwinner.crust.defconfig = "nanopi_m1_plus_defconfig";
    mmcBootIndex = "1";
  };

  Tow-Boot = {
    defconfig = "nanopi_m1_plus_defconfig";
  };
}
