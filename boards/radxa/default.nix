{ rockchipRK399 }:

{
  radxa-RockPi4C = rockchipRK399 {
    boardIdentifier = "radxa-rockPi4C";
    defconfig = "rock-pi-4c-rk3399_defconfig";
    SPISize = 4 * 1024 * 1024; # 4 MiB
    patches = [
      # Based on https://github.com/armbian/build/blob/master/patch/u-boot/u-boot-rockchip64/board-rock-pi-4-enable-spi-flash.patch
      ./0001-rockpi4-rk3399-add-spi-support.patch
      # From https://github.com/armbian/build/blob/master/patch/u-boot/u-boot-rockchip64/general-add-xtx-spi-nor-chips.patch
      ./general-add-xtx-spi-nor-chips.patch
    ];
    withSPI = true;
  };
}
