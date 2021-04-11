{ systems }:

let
  inherit (systems) aarch64;

  build = args: aarch64.buildTowBoot ({
    meta.platforms = ["aarch64-linux"];
    filesToInstall = ["u-boot.bin"];
    withPoweroff = false;
    patches = [
      ./0001-configs-rpi-allow-for-bigger-kernels.patch
    ];
  } // args);
in
{
  #
  # Raspberry Pi
  # -------------
  #
  raspberryPi-3 = build { defconfig = "rpi_3_defconfig"; };
  raspberryPi-4 = build { defconfig = "rpi_4_defconfig"; };
}
