{ config, lib, pkgs, ... }:

{
  device = {
    name = "pine64/pinephone-pro";
    dtbFiles = [
      "rockchip/rk3399-pinephone-pro.dtb"
    ];
  };

  hardware = {
    cpu = "rockchip-rk3399";
  };

  wip.kernel.package = pkgs.callPackage ./kernel {};
  wip.kernel.defconfig = ./kernel.defconfig;
  wip.kernel = {
    structuredConfig = lib.mkMerge [
      (with lib.kernel; {
        SPI = yes;
        SPI_ROCKCHIP = yes;
        MTD = yes;
        MTD_SPI_NOR = yes;
        MTD_BLOCK = yes;
      })
      (with lib.kernel; {
        KEYBOARD_ADC = yes;
        KEYBOARD_GPIO = yes;

        # dependencies for KEYBOARD_ADC
        ROCKCHIP_SARADC = yes;
        IIO = yes;
        INPUT_KEYBOARD = yes;
      })
    ];
  };

  boot.cmdline = [
    "console=ttyS2,115200n8"
    "earlycon=uart8250,mmio32,0xff1a0000"
  ];
}
