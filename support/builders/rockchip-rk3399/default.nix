{ buildTowBoot, TF-A, imageBuilder, runCommandNoCC, writeText, spiInstallerPartitionBuilder }:

# For Rockchip RK3399 based hardware
{ defconfig, postPatch ? "", postInstall ? "", extraConfig ? "", patches ? [], ... } @ args:

let
  # Currently 1.1MiB... Let's keep A LOT of room on hand.
  firmwareMaxSize = 4 * 1024 * 1024; # MiB in bytes
  partitionOffset = 64; # in sectors
  secondOffset = 16384; # in sectors
  sectorSize = 512;

  firmwarePartition = imageBuilder.firmwarePartition {
    inherit sectorSize;
    partitionOffset = partitionOffset; # in sectors
    partitionSize = firmwareMaxSize + (secondOffset * sectorSize); # in bytes
    firmwareFile = "${firmware}/firmware.shared.img";
  };

  baseImage' = extraPartitions: imageBuilder.diskImage.makeGPT {
    name = "disk-image";
    diskID = "01234567";

    partitions = [
      firmwarePartition
    ] ++ extraPartitions;
  };

  baseImage = baseImage' [];
  spiInstallerImage = baseImage' [
    (spiInstallerPartitionBuilder {
      inherit defconfig;
      firmware = "${firmware}/firmware.spiflash.bin";
    })
  ];

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

    patches = [
      ./0001-HACK-efi_runtime-pretend-we-can-t-reset.patch
    ] ++ patches;
  } // removeAttrs args [ "postPatch" "postInstall" "extraConfig" "patches" ]);
in
firmware.mkOutput ''
  cp -rv ${baseImage}/*.img $out/disk-image.img
  cp -rv ${spiInstallerImage}/*.img $out/spi-installer.img
''
