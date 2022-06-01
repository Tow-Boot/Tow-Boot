{ config, pkgs, ... }:

let
  configTxt = pkgs.writeText "config.txt" ''
    kernel=Tow-Boot.noenv.bin
    enable_uart=1
    avoid_warnings=1
  '';
in

{
  device = {
    manufacturer = "Raspberry Pi";
    name = "2 Model B";
    identifier = "raspberryPi-2";
    productPageURL = "https://www.raspberrypi.com/products/raspberry-pi-2-model-b/";
  };

  hardware = {
    soc = "generic-armv7l";
  };

  Tow-Boot = {
    defconfig = "rpi_2_defconfig";

    config = [
      (helpers: with helpers; {
        CMD_POWEROFF = no;
      })
    ];

    patches = [
      ./0001-configs-rpi-allow-for-bigger-kernels.patch
      ./0001-Tow-Boot-rpi-Increase-malloc-pool-up-to-64MiB-env.patch
    ];

    outputs.firmware = pkgs.callPackage (
      { runCommandNoCC }:

      runCommandNoCC "tow-boot-${config.device.identifier}" {
        inherit (config.Tow-Boot.outputs.firmware)
          version
          source
        ;
      } ''
        (PS4=" $ "; set -x
        mkdir -p $out/{binaries,config}
        cp -v ${config.Tow-Boot.outputs.firmware.source}/* $out/
        cp -v ${config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.noenv.bin $out/binaries/Tow-Boot.noenv.bin
        cp -v ${config.Tow-Boot.outputs.firmware}/config/noenv.config $out/config/noenv.config
        )
      ''
    ) { };

    builder.installPhase = ''
      cp -v u-boot.bin $out/binaries/Tow-Boot.$variant.bin
    '';

    # The Raspberry Pi firmware expects a filesystem to be used.
    writeBinaryToFirmwarePartition = false;

    diskImage = {
      partitioningScheme = "mbr";
    };
    firmwarePartition = {
      partitionType = "0C";
      filesystem = {
        filesystem = "fat32";
        populateCommands = ''
          cp -v ${configTxt} config.txt
          cp -v ${config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.noenv.bin Tow-Boot.noenv.bin
          (
          target="$PWD"
          cd ${pkgs.raspberrypifw}/share/raspberrypi/boot
          cp -v bcm2709-rpi-2-b.dtb "$target/"
          cp -v bcm2710-rpi-2-b.dtb "$target/"
          cp -v bootcode.bin fixup*.dat start*.elf "$target/"
          )
        '';

        # The build, since it includes misc. files from the Raspberry Pi Foundation
        # can get quite bigger, compared to other boards.
        size = 32 * 1024 * 1024;
        fat32 = {
          partitionID = "00F800F8";
        };
        label = "TOW-BOOT-FIRM";
      };
    };
  };

  documentation.sections.installationInstructions = ''
    ## Installation instructions

    ${config.documentation.helpers.genericSharedStorageInstructionsTemplate { storage = "an SD card, USB drive (if the Raspberry Pi is configured correctly) or eMMC (for systems with eMMC)"; }}
  '';
}
