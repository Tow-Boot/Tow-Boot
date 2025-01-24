{ config, lib, pkgs, ...}:

{
  imports = [
    ../pine64-pineH64A
  ];

  device = {
    name = "H64B";
    identifier = "pine64-pineH64B";
    productPageURL = "https://www.pine64.org/pine-h64-ver-b/";
  };

  hardware = {
    allwinner.crust.defconfig = "pine_h64_defconfig";
  };

  Tow-Boot = {
    defconfig = "pine_h64-model-b_defconfig";
  };
}
