{ systems }:

let
  inherit (systems) aarch64;

  build = args: aarch64.buildTowBoot ({
    extraMeta.platforms = ["aarch64-linux"];
    filesToInstall = ["u-boot.bin" ".config"];
    withPoweroff = false;
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
