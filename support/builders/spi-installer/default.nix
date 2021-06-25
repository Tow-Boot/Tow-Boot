{ lib, writeText, imageBuilder, mkScript }:

{ firmware # Firmware derivation
, flashOffset ? 0
}:

let
  inherit (firmware)
    boardIdentifier
    SPISize
  ;
  firmwareFile = "${firmware}/binaries/Tow-Boot.spi.bin";

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
  in writeText "${boardIdentifier}-flash.cmd" ''
    echo
    echo
    echo Firmware installer
    echo
    echo

    if test $board_identifier != "${boardIdentifier}"; then
      ${error ''
      echo "This is the installer for: [${boardIdentifier}]"
      echo "The board detected is:     "[$board_identifier]
      ''}
    else
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
        if sf read $ramdisk_addr_r 0 0x${lib.toHexString SPISize}; then

          echo ""
          echo "-> Reading new firmware from storage..."
          if load $devtype $devnum:$bootpart $kernel_addr_r Tow-Boot.spi.bin; then

            echo ""
            echo "-> Writing new firmware to SPI Flash..."

            if sf update $kernel_addr_r ${toString flashOffset} $filesize; then
              echo ""
              echo "✅ Flashing seems to have been successful!"
              echo ""
              if pause 'Press any key to reboot...'; then
                echo -n
              else
                echo "Resetting in 5 seconds"
                sleep 5
              fi
              reset

            else
              ${error ''
              echo "❌ Error flashing new firmware to SPI Flash."
              echo "   Rebooting now may fail."
              ''}
            fi

          else
            ${error ''
            echo "⚠️ Error reading new firmware from storage."
            echo "  Rebooting should be safe, nothing was done."
            ''}
          fi

        else
          ${error ''
          echo "⚠️ Error reading current firmware."
          echo "  Rebooting should be safe, nothing was done."
          ''}
        fi

      else
        ${error ''
        echo "⚠️ Running `sf probe` failed unexpectedly."
        echo "  Rebooting should be safe, nothing was done."
        ''}
      fi
    fi
  '';

  bootcmd = writeText "${boardIdentifier}-boot.cmd" ''
    echo
    echo "Tow-Boot SPI installer script"
    echo

    # Commands used by either menu systems, or manually.
    setenv spi_erase 'sf probe; echo "Currently erasing..."; sf erase ${toString flashOffset} +1000000; echo "Done!"; sleep 5'
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

  installerPartition = imageBuilder.fileSystem.makeExt4 {
    name = "spi-installer";
    partitionID = "44444444-4444-4444-0000-000000000003";
    size = imageBuilder.size.MiB 8;
    bootable = true;
    populateCommands = ''
      cp -v ${mkScript bootcmd} ./boot.scr
      cp -v ${mkScript flashscript} ./flash.scr
      cp -v ${firmwareFile} ./Tow-Boot.spi.bin
    '';
  };
in
  installerPartition
