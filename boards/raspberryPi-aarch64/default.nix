{ config, lib, pkgs, ... }:

{
  device = {
    manufacturer = "Raspberry Pi";
    name = "Combined AArch64";
    identifier = lib.mkDefault "raspberryPi-aarch64";
    productPageURL = "https://www.raspberrypi.com/products/";
  };

  hardware = {
    soc = "raspberryPi-arm64";
    raspberryPi = {
      upstreamKernel = false;
      configTxt.filters = {
        "pi4" = {
          enable_gic = true;
          armstub = "armstub8-gic.bin";
          disable_overscan = true;
        };
        "all" = {
          arm_64bit = true;
          enable_uart = true;
          avoid_warnings = true;
        };
      };
    };
  };

  Tow-Boot = {
    defconfig = "rpi_arm64_defconfig";
  };
}
