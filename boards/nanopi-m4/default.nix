{ lib, ... }:

{
  device = {
    manufacturer = "FriendlyARM";
    name = "NanoPi M4";
    identifier = lib.mkDefault "friendlyarm-nanopi-m4";
    productPageURL = "https://www.friendlyelec.com/index.php?route=product/product&product_id=234";
  };

  hardware = {
    soc = "rockchip-rk3399";
  };

  Tow-Boot = {
    defconfig = lib.mkDefault "nanopi-m4-rk3399_defconfig";
  };
}
