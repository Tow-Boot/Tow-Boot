{
  device = {
    manufacturer = "Olimex";
    name = "TERES-I";
    identifier = "olimex-teresI";
    productPageURL = "https://www.olimex.com/Products/DIY-Laptop/KITS/TERES-A64-BLACK/open-source-hardware";
    supportLevel = "best-effort";
  };

  hardware = {
    soc = "allwinner-a64";
  };

  Tow-Boot = {
    defconfig = "teres_i_defconfig";
  };
}
