{ buildTowBoot, TF-A, imageBuilder, runCommandNoCC, mkScript, writeText }:

# For Rockchip RK3399 based hardware
{ defconfig, postPatch ? "", postInstall ? "", extraConfig ? "", ... } @ args:

let
  # Currently 1.1MiB... Let's keep A LOT of room on hand.
  firmwareMaxSize = 4 * 1024 * 1024; # MiB in bytes
  partitionOffset = 64; # in sectors
  secondOffset = 16384; # in sectors
  sectorSize = 512;

  flashscript = writeText "${defconfig}-flash.cmd" ''
    echo
    echo
    echo Firmware installer
    echo
    echo

    # We know this is the second partition.
    if load $devtype $devnum:2 $kernel_addr_r firmware.spiflash.bin; then
      sf probe
      sf erase 0 +$filesize
      sf write $kernel_addr_r 0 $filesize
      echo "Flashing seems to have been successful! Resetting in 5 seconds"
      sleep 5
      reset
    fi
  '';

  bootcmd = writeText "${defconfig}-boot.cmd" ''
    setenv bootmenu_0 'Flash firmware to SPI=setenv script flash.scr; run boot_a_script'
    setenv bootmenu_1 'Completely erase SPI=sf probe; echo "Currently erasing..."; sf erase 0 +1000000; echo "Done!"; sleep 5; bootmenu -1'
    setenv bootmenu_2 'Reboot=reset'
    setenv bootmenu_3
    bootmenu -1
  '';

  firmwarePartition = imageBuilder.firmwarePartition {
    inherit sectorSize;
    partitionOffset = partitionOffset; # in sectors
    partitionSize = firmwareMaxSize + (secondOffset * sectorSize); # in bytes
    firmwareFile = "${firmware}/firmware.shared.img";
  };

  installerPartition = imageBuilder.fileSystem.makeExt4 {
    name = "spi-installer";
    partitionID = "44444444-4444-4444-0000-000000000003";
    size = imageBuilder.size.MiB 8;
    bootable = true;
    populateCommands = ''
      cp -v ${mkScript bootcmd} ./boot.scr
      cp -v ${mkScript flashscript} ./flash.scr
      cp -v ${firmware}/firmware.spiflash.bin ./firmware.spiflash.bin
    '';
  };

  baseImage' = extraPartitions: imageBuilder.diskImage.makeGPT {
    name = "disk-image";
    diskID = "01234567";

    partitions = [
      firmwarePartition
    ] ++ extraPartitions;
  };

  baseImage = baseImage' [];
  installerImage = baseImage' [ installerPartition ];

  firmware = buildTowBoot ({
    # Does not actually turn off tested boards...
    withPoweroff = false;

    inherit defconfig;
    inherit
      sectorSize
      partitionOffset
      secondOffset
    ;

    meta.platforms = ["aarch64-linux"];
    BL31 = "${TF-A}/bl31.elf";

    postPatch = ''
      patchShebangs arch/arm/mach-rockchip/
    '' + postPatch;

    postInstall = ''
      echo ":: Preparing image for SPI flash..."
      (PS4=" $ "; set -x
      tools/mkimage -n rk3399 -T rkspi -d tpl/u-boot-tpl-dtb.bin:spl/u-boot-spl-dtb.bin spl.bin
      # 512K here is 0x80000 CONFIG_SYS_SPI_U_BOOT_OFFS
      cat <(dd if=spl.bin bs=512K conv=sync) u-boot.itb > $out/firmware.spiflash.bin
      )

      echo ":: Preparing single file firmware image for shared storage..."
      (PS4=" $ "; set -x
      dd if=idbloader.img of=firmware.shared.img conv=fsync,notrunc bs=$sectorSize seek=$((partitionOffset - partitionOffset))
      dd if=u-boot.itb    of=firmware.shared.img conv=fsync,notrunc bs=$sectorSize seek=$((secondOffset - partitionOffset))
      cp -v firmware.shared.img $out/
      )
    '' + postInstall;

    extraConfig = ''
      # SPI boot Support
      CONFIG_MTD=y
      CONFIG_DM_MTD=y
      CONFIG_SPI_FLASH_SFDP_SUPPORT=y
      CONFIG_SPL_DM_SPI=y
      CONFIG_SPL_SPI_FLASH_TINY=n
      CONFIG_SPL_SPI_FLASH_SFDP_SUPPORT=y
      CONFIG_SYS_SPI_U_BOOT_OFFS=0x80000 # 512K
      CONFIG_SPL_DM_SEQ_ALIAS=y
    '' + extraConfig;
  } // removeAttrs args [ "postPatch" "postInstall" "extraConfig" ]);
in
runCommandNoCC firmware.name {
  inherit
    sectorSize
    partitionOffset
    secondOffset
  ;
} ''
  mkdir -p "$out"
  cp -rvt $out/ ${firmware}/.config
  cp -rvt $out/ ${firmware}/*
  cp -rv ${baseImage}/*.img $out/disk-image.img
  cp -rv ${installerImage}/*.img $out/spi-installer.img
''
