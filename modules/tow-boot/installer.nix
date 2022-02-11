{ config, lib, pkgs, ... }:

let
  inherit (lib)
    concatStringsSep
    mkIf
    mkMerge
    mkOption
    optionalString
    types
  ;

  inherit (pkgs)
    writeText
  ;
  inherit (pkgs.Tow-Boot)
    mkScript
  ;

  inherit (config.hardware)
    mmcBootIndex
  ;

  isPhoneUX = config.Tow-Boot.phone-ux.enable;

  installerType =
    if config.Tow-Boot.installer.enable
    then config.Tow-Boot.installer.targetConfig.Tow-Boot.variant
    else null
  ;

  prettyType = {
    "spi" = "SPI";
    "mmcboot" = "eMMC Boot";
  }.${installerType};

  bootcmd = writeText "${config.device.identifier}-boot.cmd" ''
    echo
    echo "Tow-Boot ${prettyType} installer script"
    echo

    # Commands used by either menu systems, or manually.
    ${optionalString (installerType == "spi") ''
      setenv spi_erase '${concatStringsSep ";" [
        ''sf probe''
        ''echo "Currently erasing..."''
        ''sf erase 0 0x${lib.toHexString config.hardware.SPISize}''
        ''echo "Done!"''
        ''sleep 5''
      ]}'
    ''}
    ${optionalString (installerType == "mmcboot") ''
      setenv mmcboot_erase '${concatStringsSep ";" [
        ''mmc dev ${mmcBootIndex} 1''
        ''mmc erase 0 2000''
        ''mmc dev ${mmcBootIndex} 2''
        ''mmc erase 0 2000''
        ''echo "Done!"''
        ''sleep 5''
      ]}'
    ''}
    setenv ${installerType}_flash 'setenv script flash.scr; run boot_a_script'

    setenv bootmenu_0 'Flash firmware to ${prettyType}=run ${installerType}_flash'
    ${optionalString (installerType == "spi") ''
      setenv bootmenu_1 'Completely erase SPI=run spi_erase'
    ''}
    ${optionalString (installerType == "mmcboot") ''
      setenv bootmenu_1 'Erase platform firmware from eMMC Boot=run mmcboot_erase'
    ''}
    setenv bootmenu_2 'Reboot=reset'
    setenv bootmenu_3


    while true; do
      if tb_menu new; then
        tb_menu add 'Flash firmware to ${prettyType}' "" 'run ${installerType}_flash'
    ${optionalString (installerType == "spi") ''
        tb_menu add 'Completely erase ${prettyType}'  "" 'run ${installerType}_erase'
    ''}
    ${optionalString (installerType == "mmcboot") ''
        tb_menu add 'Erase firmware from ${prettyType}'  "" 'run ${installerType}_erase'
    ''}
        tb_menu separator
        tb_menu add 'Reboot' 'Reboots the device' 'reset'
        tb_menu show
      else
        if bootmenu -1; then
          echo -n
        else
          echo
          echo '****************************'
          echo '* No menu system available *'
          echo '****************************'
          echo
          echo 'Use `run ${installerType}_erase` to erase the ${prettyType}.'
          echo
          echo 'Use `run ${installerType}_flash` to erase and flash to ${prettyType}.'
          echo
          echo 'Use `reset` to reset the system.'
          echo
          exit
        fi
      fi
    done
  '';

  spiFlashscript = let
    error = messages: ''
      echo ""
      echo " ********* "
      echo " * ERROR * "
      echo " ********* "
      echo ""
      ${messages}
      echo ""
      if pause 'Press any key to go back to the menu...'; then
        echo -n
      else
        echo ""
        echo "* * * Returning to the menu in 60 seconds"
        echo ""
        sleep 60
      fi
    '';
  in writeText "${config.device.identifier}-flash.cmd" ''
    echo
    echo
    echo Firmware installer
    echo
    echo

    if test $board_identifier != "${config.device.identifier}"; then
      ${error ''
      echo "This is the installer for: [${config.device.identifier}]"
      echo "The board detected is:     "[$board_identifier]
      ''}
    else
      # Some variables we will be using
      # (Useless use of setexpr, but eh)
      setexpr new_firmware_addr_r $kernel_addr_r + 0
      setexpr old_firmware_addr_r $ramdisk_addr_r + 0
      setexpr new_firmware_addr_r_tail $new_firmware_addr_r + 0x2000

      echo "devtype = $devtype"
      echo "devnum = $devnum"
      part list $devtype $devnum -bootable bootpart
      echo "bootpart = $bootpart"
      echo ""
      echo ":: Starting flash operation"
      echo ""

      echo "-> Initializing SPI Flash subsystem..."
      if sf probe; then

        echo ""
        echo "-> Reading Flash content..."
        if sf read $old_firmware_addr_r 0 0x${lib.toHexString config.hardware.SPISize}; then

          echo ""
          echo "-> Reading new firmware from storage..."
          if load $devtype $devnum:$bootpart $new_firmware_addr_r Tow-Boot.spi.bin; then
            setexpr new_firmware_size $filesize + 0
            setexpr new_firmware_size_tail $filesize - 0x2000

            echo ""
            echo "-> Hardening against failures..."
            echo "   We are deliberately breaking the initial part of the SPI Flash contents."
            # Safe only if the Boot ROM can read from alternate sources!!

            # Erasing the first 8KiB of the SPI Flash
            # With all tested devices, the Boot ROM will not use the SPI Flash.
            # This helps ensure a failure in the following steps does not brick the device.
            if sf erase 0x0 0x2000; then
              echo ""
              echo "   A stray reboot should be safe now."

              echo ""
              echo "-> Writing new firmware tail to SPI Flash..."
              if sf update $new_firmware_addr_r_tail 0x2000 $new_firmware_size_tail; then

                echo ""
                echo "-> Writing new firmware head to SPI Flash..."
                if sf update $new_firmware_addr_r 0x0 0x2000; then

                  echo ""
                  echo "✅ Flashing seems to have been successful!"
                  echo ""
                  if pause 'Press any key to reboot...'; then
                    echo -n
                  else
                    echo "Resetting in 5 seconds"
                    sleep 5
                  fi
                  reset

                # sf update head
                else
                  ${error ''
                  echo "❌ Error flashing new firmware head to SPI Flash."
                  echo "   Rebooting now may fail."
                  ''}
                fi

              # sf update tail
              else
                ${error ''
                echo "⚠️ Error flashing new firmware tail to SPI Flash."
                echo "  Rebooting now should be safe as the SPI was removed from the boot chain."
                ''}
              fi

            # sf erase 0x2000
            else
              ${error ''
              echo "❌ Failed to harden against failures."
              echo "   If is unknown whether rebooting is safe or not right now."
              ''}
            fi

          # load Tow-Boot.spi.bin
          else
            ${error ''
            echo "⚠️ Error reading new firmware from storage."
            echo "  Rebooting should be safe, nothing was done."
            ''}
          fi

        # sf read
        else
          ${error ''
          echo "⚠️ Error reading current firmware."
          echo "  Rebooting should be safe, nothing was done."
          ''}
        fi

      # sf probe
      else
        ${error ''
        echo "⚠️ Running `sf probe` failed unexpectedly."
        echo "  Rebooting should be safe, nothing was done."
        ''}
      fi
    fi
  '';

  mmcBootFlashscript = let
    error = messages: ''
      echo ""
      echo " ********* "
      echo " * ERROR * "
      echo " ********* "
      echo ""
      ${messages}
      echo ""
      if pause 'Press any key to go back to the menu...'; then
        echo -n
      else
        echo ""
        echo "* * * Returning to the menu in 60 seconds"
        echo ""
        sleep 60
      fi
    '';
  in writeText "${config.device.identifier}-flash.cmd" ''
    echo
    echo
    echo eMMC Boot Firmware installer
    echo
    echo

    if test $board_identifier != "${config.device.identifier}"; then
      ${error ''
      echo "This is the installer for: [${config.device.identifier}]"
      echo "The board detected is:     "[$board_identifier]
      ''}
    else
      # Some variables we will be using
      # (Useless use of setexpr, but eh)
      setexpr new_firmware_addr_r $kernel_addr_r + 0
      setexpr new_firmware_addr_r_tail $new_firmware_addr_r + 0x2000

      echo "devtype = $devtype"
      echo "devnum = $devnum"
      part list $devtype $devnum -bootable bootpart
      echo "bootpart = $bootpart"
      echo ""
      echo ":: Starting flash operation"
      echo ""

      echo "-> Targeting MMC${mmcBootIndex}..."
      if mmc dev ${mmcBootIndex} 1; then

        echo ""
        echo "-> Reading new firmware from storage..."
        if load $devtype $devnum:$bootpart $new_firmware_addr_r Tow-Boot.mmcboot.bin; then
          # Assumes 512 bytes blocks.
          # It is the maximum value it can be, and the most likely value.
          # Block sizes smaller than 512 are not expected.
          #  - https://source.denx.de/u-boot/u-boot/-/blob/v2022.01/drivers/mmc/mmc.c#L2540-2543
          # Furthermore, JESD84-A43 states 512 bytes read/write support must be supported.
          # This *should* mean that in practice 512 is the value used all the time.
          #   ¯\_(ツ)_/¯
          blocksize=0x200
          setexpr neutersize 0x2000 / $blocksize
          # rounded-up integer division is `(a+b-1) / b`
          setexpr new_firmware_size_blocks $filesize + $blocksize
          setexpr new_firmware_size_blocks $new_firmware_size_blocks - 1
          setexpr new_firmware_size_blocks $new_firmware_size_blocks / $blocksize
          setexpr new_firmware_size_tail_blocks $new_firmware_size_blocks - $neutersize

          echo ""
          echo "-> Hardening against failures..."
          echo "   We are deliberately breaking the initial part of the eMMC Boot Flash contents."
          # Safe only if the Boot ROM can read from alternate sources!!

          # Erasing the first 8KiB of the eMMC Boot Flash
          # With all tested devices, this is sufficient to neuter.
          # This helps ensure a failure in the following steps does not brick the device.
          if mmc erase 0 $neutersize; then
            echo ""
            echo "   A stray reboot should be safe now."

            echo ""
            echo "-> Writing new firmware tail to eMMC Boot..."
            if mmc write $new_firmware_addr_r_tail $neutersize $new_firmware_size_tail_blocks; then

              echo ""
              echo "-> Writing new firmware head to eMMC Boot..."
              if mmc write $new_firmware_addr_r 0x0 $neutersize; then
                ${config.Tow-Boot.installer.additionalMMCBootCommands}

                echo ""
                echo "✅ Flashing seems to have been successful!"
                echo ""
                if pause 'Press any key to reboot...'; then
                  echo -n
                else
                  echo "Resetting in 5 seconds"
                  sleep 5
                fi
                reset

              # mmc write head
              else
                ${error ''
                echo "❌ Error flashing new firmware head to eMMC Boot."
                echo "   Rebooting now may fail."
                ''}
              fi

            # mmc write tail
            else
              ${error ''
              echo "⚠️ Error flashing new firmware tail to eMMC Boot."
              echo "  Rebooting now should be safe as the eMMC Boot was removed from the boot chain."
              ''}
            fi

          # mmc erase 0 0x2000
          else
            ${error ''
            echo "❌ Failed to harden against failures."
            echo "   If is unknown whether rebooting is safe or not right now."
            ''}
          fi

        # load Tow-Boot.mmcboot.bin
        else
          ${error ''
          echo "⚠️ Error reading new firmware from storage."
          echo "  Rebooting should be safe, nothing was done."
          ''}
        fi

      # sf probe
      else
        ${error ''
        echo "⚠️ Running `mmc dev ${mmcBootIndex} 1` failed unexpectedly."
        echo "  Rebooting should be safe, nothing was done."
        ''}
      fi
    fi
  '';

in
{
  options = {
    Tow-Boot = {
      installer = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Using `composeConfig`, enable to build a specific installer.
          '';
        };
        targetConfig = mkOption {
          # A NixOS modules system eval
          type = types.unspecified;
          description = ''
            Installer eval to be installed by the installer.
          '';
        };
        additionalMMCBootCommands = mkOption {
          type = types.lines;
          default = "";
          description = ''
            Additional commands to run after successfully writing the firmware to the mmcboot partition.
          '';
        };
      };
      touch-installer = {
        eval = mkOption {
          type = types.unspecified;
          internal = true;
          description = ''
            The Celun eval for the installer system.
          '';
        };
        partitionContent = mkOption {
          type = types.package;
          description  = ''
            The partition content for the installer system.
          '';
        };
      };
    };
  };

  config = mkMerge [
    (mkIf (installerType == "spi" && !isPhoneUX) {
      Tow-Boot.diskImage = {
        partitions = [
          {
            partitionType = lib.mkDefault (
              if config.Tow-Boot.diskImage.partitioningScheme == "gpt"
              then "0FC63DAF-8483-4772-8E79-3D69D8477DE4"
              else "83"
            );
            partitionUUID = "44444444-4444-4444-0000-000000000003";
            filesystem = {
              filesystem = "ext4";
              populateCommands = ''
                cp -v ${mkScript bootcmd} ./boot.scr
                cp -v ${mkScript spiFlashscript} ./flash.scr
                cp -v "${config.build.firmwareSPI}/binaries/Tow-Boot.spi.bin" ./Tow-Boot.spi.bin
              '';
              size = 8 * 1024 * 1024;
            };
            name = "spi-installer";
            bootable = true;
          }
        ];
      };
    })
    (mkIf (installerType == "spi" && isPhoneUX) {
      Tow-Boot = {
        diskImage = {
          partitions = [
            {
              partitionType = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
              partitionUUID = "44444444-4444-4444-0000-000000000003";
              filesystem = {
                filesystem = "ext4";
                populateCommands = ''
                  cp -vt ./ ${config.Tow-Boot.touch-installer.partitionContent}/*
                '';
                extraPadding = 8 * 1024 * 1024;
              };
              name = "spi-installer";
              bootable = true;
            }
          ];
        };
        touch-installer = {
          eval =
            (import ../../embedded-linux-os/touch-installer-app {
              device = ../../embedded-linux-os/devices/${config.device.identifier};
              configuration = {
                Tow-Boot.installer.config = {
                  deviceName = "${config.device.manufacturer} ${config.device.name}";
                  payload = "${config.build.firmwareSPI}/binaries/Tow-Boot.spi.bin";
                  # TODO: support more than SPI installs
                  storageMedia = "SPI";
                  targetBlockDevice = "/dev/mtdblock0";
                };
              };
            })
          ;
          inherit ((config.Tow-Boot.touch-installer.eval).config.wip.u-boot.output)
            partitionContent
          ;
        };
      };
    })
    (mkIf (installerType == "mmcboot") {
      Tow-Boot.diskImage = {
        partitions = [
          {
            partitionType = lib.mkDefault (
              if config.Tow-Boot.diskImage.partitioningScheme == "gpt"
              then "0FC63DAF-8483-4772-8E79-3D69D8477DE4"
              else "83"
            );
            partitionUUID = "44444444-4444-4444-0000-000000000004";
            filesystem = {
              filesystem = "ext4";
              populateCommands = ''
                cp -v ${mkScript bootcmd} ./boot.scr
                cp -v ${mkScript mmcBootFlashscript} ./flash.scr
                cp -v "${config.build.firmwareMMCBoot}/binaries/Tow-Boot.mmcboot.bin" ./Tow-Boot.mmcboot.bin
              '';
              size = 8 * 1024 * 1024;
            };
            name = "mmcboot-installer";
            bootable = true;
          }
        ];
      };
    })
  ];
}
