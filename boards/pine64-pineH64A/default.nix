{ config, lib, pkgs, ...}:

{
  device = {
    manufacturer = "PINE64";
    name = lib.mkDefault "H64A";
    identifier = lib.mkDefault "pine64-pineH64A";
    productPageURL = "https://www.pine64.org/pine-h64/";
  };

  hardware = {
    soc = "allwinner-h6";
    withDisplay = false;
    SPISize = 16 * 1024 * 1024; # 16 MiB
  };

  Tow-Boot = {
    defconfig = lib.mkDefault "pine_h64_defconfig";
    patches = [
      ./0001-sunxi-dts-add-device-tree-for-pine-H64-model-B.patch
      ./0002-sunxi-configs-add-defconfig-for-pine-H64-model-B.patch
      ./0003-sunxi-SPI-fix-pinmuxing-for-Allwinner-H6-SoCs.patch
      ./0004-pine-H64-A-enable-SPI-disable-eMMC.patch
      ./0005-pine-H64-B-enable-SPI-disable-eMMC.patch
    ];
    config = [
      (helpers: with helpers; {
        CMD_POWEROFF = no;
      })
    ];
  };
}
