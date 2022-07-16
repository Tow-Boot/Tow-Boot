{
  device = {
    manufacturer = "Banana Pi";
    name = "P2 Maker";
    identifier = "bananaPi-p2Maker";
    productPageURL = "https://wiki.banana-pi.org/Banana_Pi_BPI-P2_Zero";
  };

  hardware = {
    soc = "allwinner-h3";
  };

  Tow-Boot = {
    defconfig = "bananapi_p2_maker_defconfig";
    patches = [
      ./0001-sunxi-add-Banana-Pi-P2-Maker.patch
    ];
  };
}
