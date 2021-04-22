{ config, lib, pkgs, ... }:

let
  blobs = pkgs.callPackage ./blobs.nix { };

  # NOTE: Some Helios64 are marginal with higher RAM speed.
  #       This is why we are selecting the lowest available.
  #       Only increase if you have an in-depth test for stability.
  ram_init = blobs.ram_init-1_24-666;
in
{
  device = {
    manufacturer = "Kobol";
    name = "Helios64";
    identifier = "kobol-helios64";
    # Actual product page is https://kobol.io/
    # But since it's the vendor's homepage, it's not deemed suitable.
    productPageURL = "https://wiki.kobol.io/helios64/intro/";
  };

  hardware = {
    soc = "rockchip-rk3399";

    # FIXME: fix for SPI use with proprietary RAM init
    #SPISize = 16 * 1024 * 1024; # 16 MiB

    # TODO: fix this eventually.
    withDisplay = false;
  };

  Tow-Boot = {
    defconfig = "helios64-rk3399_defconfig";
    # Though this will already have been done.
    setup_leds = "led helios64::status on";

    builder.additionalArguments = {
      inherit ram_init;
    };

    patches = [
      # Use armbian's board enablement.
      # The upstream U-Boot one has less features enabled and working.
      ./patches/0001-helios64-Add-board.patch
      ./patches/0001-helios64-support-SPI-flash-boot.patch
    ];
  };
}
