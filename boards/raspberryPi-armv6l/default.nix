{ config, lib, pkgs, ... }:

let
  inherit (config.helpers)
    composeConfig
  ;
  raspberryPi-0 = composeConfig {
    config = {
      device.identifier = "raspberryPi-0";
      Tow-Boot.defconfig = "rpi_0_w_defconfig";
    };
  };
  raspberryPi-1 = composeConfig {
    config = {
      device.identifier = "raspberryPi-1";
      Tow-Boot.defconfig = "rpi_defconfig";
    };
  };
  raspberryPi-2 = composeConfig {
    config = {
      device.identifier = "raspberryPi-2";
      Tow-Boot.defconfig = "rpi_2_defconfig";
    };
  };
  raspberryPi-3 = composeConfig {
    config = {
      device.identifier = "raspberryPi-3";
      Tow-Boot.defconfig = "rpi_3_32b_defconfig";
    };
  };
  raspberryPi-4 = composeConfig {
    config = {
      device.identifier = "raspberryPi-4";
      Tow-Boot.defconfig = "rpi_4_32b_defconfig";
    };
  };

  configTxt = pkgs.writeText "config.txt" ''
    [pi0]
    kernel=Tow-Boot.noenv.rpi0.bin

    [pi1]
    kernel=Tow-Boot.noenv.rpi1.bin

    [pi2]
    kernel=Tow-Boot.noenv.rpi2.bin

    [pi3]
    kernel=Tow-Boot.noenv.rpi3.bin

    [pi4]
    kernel=Tow-Boot.noenv.rpi4.bin

    [all]
    arm_64bit=0
    enable_uart=1
    avoid_warnings=1
  '';
in
{
  device = {
    manufacturer = "Raspberry Pi";
    name = "Combined armv6l";
    identifier = lib.mkDefault "raspberryPi-armv6l";
    productPageURL = "https://www.raspberrypi.com/products/";
    # This line of boards is YMMV.
    supportLevel = "experimental";
  };

  hardware = {
    # Targets multiple broadcom SoCs
    soc = "generic-armv6l";
  };

  Tow-Boot = {
    # FIXME: a small lie for now until we get the upcoming changes in.
    defconfig = lib.mkDefault "rpi_armhf_defconfig";

    config = [
      (helpers: with helpers; {
        # 32 MiB; the default unconfigured state is 4 MiB.
        SYS_MALLOC_LEN = freeform ''0x2000000'';
        CMD_POWEROFF = no;
      })

      (lib.mkIf (!config.Tow-Boot.buildUBoot) (helpers: with helpers; {
        # As far as distro_bootcmd is aware, the raspberry pi can
        # have up to three mmc "devices"
        #   - https://source.denx.de/u-boot/u-boot/-/blob/v2022.07/include/configs/rpi.h#L134-137
        # To be fixed in a refresh of the raspberry pi configs.
        # This currently adds two bogus "SD" entries *sigh*.
        # It's not an issue upstream since there is no menu; the bootcmd simply tries
        # all options in order. The bogus entries simply fail.
        TOW_BOOT_MMC0_NAME = freeform ''"SD (0)"'';
        TOW_BOOT_MMC1_NAME = freeform ''"SD (1)"'';
        TOW_BOOT_MMC2_NAME = freeform ''"SD (2)"'';
      }))
    ];
    outputs.firmware = lib.mkIf (config.device.identifier == "raspberryPi-armv6l") (
      pkgs.callPackage (
        { runCommand }:

        runCommand "tow-boot-${config.device.identifier}" {
          inherit (raspberryPi-1.config.Tow-Boot.outputs.firmware)
            version
          ;
        } ''
          (PS4=" $ "; set -x
          mkdir -p $out/{binaries,config,diff}
          cp -v ${raspberryPi-0.config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.noenv.bin $out/binaries/Tow-Boot.noenv.rpi0.bin
          cp -v ${raspberryPi-0.config.Tow-Boot.outputs.firmware}/config/noenv.config $out/config/noenv.rpi0.config
          cp -v ${raspberryPi-0.config.Tow-Boot.outputs.firmware}/config/noenv.newdefconfig $out/config/noenv.rpi0.newdefconfig
          cp -v ${raspberryPi-0.config.Tow-Boot.outputs.firmware}/diff/noenv.build.diff $out/diff/noenv.rpi0.diff

          cp -v ${raspberryPi-1.config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.noenv.bin $out/binaries/Tow-Boot.noenv.rpi1.bin
          cp -v ${raspberryPi-1.config.Tow-Boot.outputs.firmware}/config/noenv.config $out/config/noenv.rpi1.config
          cp -v ${raspberryPi-1.config.Tow-Boot.outputs.firmware}/config/noenv.newdefconfig $out/config/noenv.rpi1.newdefconfig
          cp -v ${raspberryPi-1.config.Tow-Boot.outputs.firmware}/diff/noenv.build.diff $out/diff/noenv.rpi1.diff

          cp -v ${raspberryPi-2.config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.noenv.bin $out/binaries/Tow-Boot.noenv.rpi2.bin
          cp -v ${raspberryPi-2.config.Tow-Boot.outputs.firmware}/config/noenv.config $out/config/noenv.rpi2.config
          cp -v ${raspberryPi-2.config.Tow-Boot.outputs.firmware}/config/noenv.newdefconfig $out/config/noenv.rpi2.newdefconfig
          cp -v ${raspberryPi-2.config.Tow-Boot.outputs.firmware}/diff/noenv.build.diff $out/diff/noenv.rpi2.diff

          cp -v ${raspberryPi-3.config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.noenv.bin $out/binaries/Tow-Boot.noenv.rpi3.bin
          cp -v ${raspberryPi-3.config.Tow-Boot.outputs.firmware}/config/noenv.config $out/config/noenv.rpi3.config
          cp -v ${raspberryPi-3.config.Tow-Boot.outputs.firmware}/config/noenv.newdefconfig $out/config/noenv.rpi3.newdefconfig
          cp -v ${raspberryPi-3.config.Tow-Boot.outputs.firmware}/diff/noenv.build.diff $out/diff/noenv.rpi3.diff

          cp -v ${raspberryPi-4.config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.noenv.bin $out/binaries/Tow-Boot.noenv.rpi4.bin
          cp -v ${raspberryPi-4.config.Tow-Boot.outputs.firmware}/config/noenv.config $out/config/noenv.rpi4.config
          cp -v ${raspberryPi-4.config.Tow-Boot.outputs.firmware}/config/noenv.newdefconfig $out/config/noenv.rpi4.newdefconfig
          cp -v ${raspberryPi-4.config.Tow-Boot.outputs.firmware}/diff/noenv.build.diff $out/diff/noenv.rpi4.diff
          )
        ''
      ) { }
    );
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
          cp -v ${raspberryPi-0.config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.noenv.bin Tow-Boot.noenv.rpi0.bin
          cp -v ${raspberryPi-1.config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.noenv.bin Tow-Boot.noenv.rpi1.bin
          cp -v ${raspberryPi-2.config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.noenv.bin Tow-Boot.noenv.rpi2.bin
          cp -v ${raspberryPi-3.config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.noenv.bin Tow-Boot.noenv.rpi3.bin
          cp -v ${raspberryPi-4.config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.noenv.bin Tow-Boot.noenv.rpi4.bin
          (
          target="$PWD"
          cd ${pkgs.raspberrypifw}/share/raspberrypi/boot
          cp -v bcm*-rpi*.dtb "$target/"
          cp -v bootcode.bin fixup*.dat start*.elf "$target/"
          )
        '';

        # The build, since it includes misc. files from the Raspberry Pi Foundation
        # can get quite bigger, compared to other boards.
        size = 32 * 1024 * 1024;
        fat32 = {
          partitionID = "00F800F8";
        };
        label = "TOW-BOOT-FW";
      };
    };
  };
  documentation.sections.installationInstructions = ''
    ## Installation instructions

    ${config.documentation.helpers.genericSharedStorageInstructionsTemplate { storage = "an SD card, USB drive (if the Raspberry Pi is configured correctly) or eMMC (for systems with eMMC)"; }}
  '';
}
