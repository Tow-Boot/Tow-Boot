{
  device = {
    manufacturer = "FriendlyELEC";
    name = "NanoPi K1 Plus";
    identifier = "friendlyElec-nanoPiK1Plus";
    productPageURL = "https://wiki.friendlyelec.com/wiki/index.php/NanoPi_K1_Plus";
  };

  hardware = {
    soc = "allwinner-h5";
  };

  Tow-Boot = {
    defconfig = "nanopi_k1_plus_defconfig";
    patches = [
      ./0001-nanopi-k1-plus-board-enablement.patch
    ];
    builder.additionalArguments = {
      SCP = "/dev/null";
    };
  };
}
