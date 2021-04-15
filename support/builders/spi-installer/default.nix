{ writeText, imageBuilder, mkScript }:

{ defconfig
, flashOffset ? 0
, flashscript ? null
, bootcmd ? null
, firmware # Path to the firmware
}:

let
  flashscript' = writeText "${defconfig}-flash.cmd" (
    if flashscript == null then ''
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
        echo "Flashing seems to have been successful! Resetting in 5 seconds"
        sleep 5
        reset
      fi
    '' else flashscript
  );

  bootcmd' = writeText "${defconfig}-boot.cmd" (
    if bootcmd == null then ''
      setenv bootmenu_0 'Flash firmware to SPI=setenv script flash.scr; run boot_a_script'
      setenv bootmenu_1 'Completely erase SPI=sf probe; echo "Currently erasing..."; sf erase ${toString flashOffset} +1000000; echo "Done!"; sleep 5; bootmenu -1'
      setenv bootmenu_2 'Reboot=reset'
      setenv bootmenu_3
      bootmenu -1
    '' else bootcmd
  );

  installerPartition = imageBuilder.fileSystem.makeExt4 {
    name = "spi-installer";
    partitionID = "44444444-4444-4444-0000-000000000003";
    size = imageBuilder.size.MiB 8;
    bootable = true;
    populateCommands = ''
      cp -v ${mkScript bootcmd'} ./boot.scr
      cp -v ${mkScript flashscript'} ./flash.scr
      cp -v ${firmware} ./firmware.spiflash.bin
    '';
  };
in
  installerPartition
