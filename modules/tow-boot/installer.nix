{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
  ;

  inherit (pkgs)
    writeText
  ;
  inherit (pkgs.Tow-Boot)
    mkScript
  ;

  installerType =
    if config.Tow-Boot.installer.enable
    then config.Tow-Boot.installer.targetConfig.Tow-Boot.variant
    else null
  ;

  bootcmd = writeText "${config.device.identifier}-boot.cmd" ''
    echo
    echo "Tow-Boot SPI installer script"
    echo

    # Commands used by either menu systems, or manually.
    setenv spi_erase 'sf probe; echo "Currently erasing..."; sf erase 0 0x${lib.toHexString config.hardware.SPISize}; echo "Done!"; sleep 5'
    setenv spi_flash 'setenv script flash.scr; run boot_a_script'

    setenv bootmenu_0 'Flash firmware to SPI=run spi_flash'
    setenv bootmenu_1 'Completely erase SPI=run spi_erase'
    setenv bootmenu_2 'Reboot=reset'
    setenv bootmenu_3


    while true; do
      if tb_menu new; then
        tb_menu add 'Flash firmware to SPI' "" 'run spi_flash'
        tb_menu add 'Completely erase SPI'  "" 'run spi_erase'
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
          echo 'Use `run spi_erase` to erase the SPI.'
          echo
          echo 'Use `run spi_flash` to erase and flash to SPI.'
          echo
          echo 'Use `reset` to reset the system.'
          echo
          exit
        fi
      fi
    done
  '';

  flashscript = let
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
      };
    };
  };

  config = mkMerge [
    (mkIf (installerType == "spi") {
      Tow-Boot.diskImage = {
        partitions = [
          {
            partitionType = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
            partitionUUID = "44444444-4444-4444-0000-000000000003";
            filesystem = {
              filesystem = "ext4";
              populateCommands = ''
                cp -v ${mkScript bootcmd} ./boot.scr
                cp -v ${mkScript flashscript} ./flash.scr
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
  ];
}
