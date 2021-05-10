{ writeText, imageBuilder, mkScript }:

{ defconfig
, flashOffset ? 0
, firmware # Path to the firmware
}:

let
  flashscript = writeText "${defconfig}-flash.cmd" ''
    echo
    echo
    echo Firmware installer
    echo
    echo

    echo "devtype = $devtype"
    echo "devnum = $devnum"
    part list $devtype $devnum -bootable bootpart
    echo "bootpart = $bootpart"
    echo ""
    echo ":: Starting flash operation"
    echo ""
    if load $devtype $devnum:$bootpart $kernel_addr_r firmware.spiflash.bin; then
      sf probe
      sf erase ${toString flashOffset} +$filesize
      sf write $kernel_addr_r ${toString flashOffset} $filesize
      echo "Flashing seems to have been successful!"

      if pause 'Press any key to reboot...'; then
        echo -n
      else
        echo "Resetting in 5 seconds"
        sleep 5
      fi
      reset
    fi
  '';

  bootcmd = writeText "${defconfig}-boot.cmd" ''
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
      cp -v ${firmware} ./firmware.spiflash.bin
    '';
  };
in
  installerPartition
