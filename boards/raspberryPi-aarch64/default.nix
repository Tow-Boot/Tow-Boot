{ config, lib, pkgs, ... }:

let
  inherit (config.helpers)
    composeConfig
  ;
  raspberryPi-3 = composeConfig {
    config = {
      device.identifier = "raspberryPi-3";
      Tow-Boot.defconfig = "rpi_3_defconfig";
    };
  };
  raspberryPi-4 = composeConfig {
    config = {
      device.identifier = "raspberryPi-4";
      Tow-Boot.defconfig = "rpi_4_defconfig";
    };
  };
in
{
  device = {
    manufacturer = "Raspberry Pi";
    name = "Combined AArch64";
    identifier = lib.mkDefault "raspberryPi-aarch64";
  };

  hardware = {
    # Targets multiple broadcom SoCs
    soc = "generic-aarch64";
  };

  Tow-Boot = {
    config = [
      (helpers: with helpers; {
        CMD_POWEROFF = no;
      })
    ];
    patches = [
      ./0001-configs-rpi-allow-for-bigger-kernels.patch
      ./0001-Tow-Boot-rpi-Increase-malloc-pool-up-to-64MiB-env.patch
    ];
    outputs.firmware = lib.mkIf (config.device.identifier == "raspberryPi-aarch64") (
      pkgs.callPackage (
        { runCommandNoCC }:

        runCommandNoCC "tow-boot-${config.device.identifier}" { } ''
          (PS4=" $ "; set -x
          mkdir -p $out/{binaries,config}
          cp -v ${raspberryPi-3.config.Tow-Boot.outputs.firmware.source}/* $out/
          cp -v ${raspberryPi-3.config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.noenv.bin $out/binaries/Tow-Boot.noenv.rpi3.bin
          cp -v ${raspberryPi-3.config.Tow-Boot.outputs.firmware}/config/noenv.config $out/config/noenv.rpi3.config

          cp -v ${raspberryPi-4.config.Tow-Boot.outputs.firmware.source}/* $out/
          cp -v ${raspberryPi-4.config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.noenv.bin $out/binaries/Tow-Boot.noenv.rpi4.bin
          cp -v ${raspberryPi-4.config.Tow-Boot.outputs.firmware}/config/noenv.config $out/config/noenv.rpi4.config
          )
        ''
      ) { }
    );
    builder.installPhase = ''
      cp -v u-boot.bin $out/binaries/Tow-Boot.$variant.bin
    '';
  };
}
