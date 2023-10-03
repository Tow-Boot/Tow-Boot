{ lib, ... }:

{
  device = {
    manufacturer = "Radxa";
    name = lib.mkDefault "ROCK 5 model B";
    identifier = lib.mkDefault "radxa-Rock5B"; # TODO Check if correct
    productPageURL = "https://wiki.radxa.com/Rock5/5b";
  };

  hardware = {
    soc = "rockchip-rk3588";
    # SPISize = 4 * 1024 * 1024; # 4 MiB
  };

  Tow-Boot = {
    defconfig = lib.mkDefault "rock5b-rk3588_defconfig";
    variant = "noenv";
    withLogo = false;
    config = [
      (helpers: with helpers; {
	# TODO Should these be here or in hardware/rockchip/default.nix
	BMP = lib.mkForce yes;
	VIDEO = lib.mkForce yes;
      })
    ];
    # TODO I guess we don't need these
    # patches = [
    #   # Based on https://github.com/armbian/build/blob/master/patch/u-boot/u-boot-rockchip64/board-rock-pi-4-enable-spi-flash.patch
    #   ./0001-rockpi4-rk3399-add-spi-support.patch
    #   # From https://github.com/armbian/build/blob/master/patch/u-boot/u-boot-rockchip64/general-add-xtx-spi-nor-chips.patch
    #   ./general-add-xtx-spi-nor-chips.patch
    # ];
  };
}
