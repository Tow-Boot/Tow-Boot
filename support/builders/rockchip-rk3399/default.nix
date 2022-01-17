{ lib, buildTowBoot, TF-A, imageBuilder, runCommandNoCC, writeText, spiInstallerPartitionBuilder, fetchpatch }:

# For Rockchip RK3399 based hardware
{ postPatch ? "", postInstall ? "", extraConfig ? "", patches ? [], withSPI ? true, ... } @ args:

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
    firmwareFile = "${firmware}/binaries/Tow-Boot.noenv.bin";
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
      firmware = firmwareSPI;
    })
  ];

  firmware' = variant: buildTowBoot ({
    inherit variant;

    # Does not actually turn off tested boards...
    withPoweroff = false;

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

    installPhase = ''
      ${lib.optionalString (variant == "spi") ''
        echo ":: Preparing image for SPI flash..."
        (PS4=" $ "; set -x
        tools/mkimage -n rk3399 -T rkspi -d tpl/u-boot-tpl-dtb.bin:spl/u-boot-spl-dtb.bin spl.bin
        # 512K here is 0x80000 CONFIG_SYS_SPI_U_BOOT_OFFS
        cat <(dd if=spl.bin bs=512K conv=sync) u-boot.itb > $out/binaries/Tow-Boot.$variant.bin
        )
      ''}

      ${lib.optionalString (variant != "spi") ''
        echo ":: Preparing single file firmware image for shared storage..."
        (PS4=" $ "; set -x
        dd if=idbloader.img of=Tow-Boot.$variant.bin conv=fsync,notrunc bs=$sectorSize seek=$((partitionOffset - partitionOffset))
        dd if=u-boot.itb    of=Tow-Boot.$variant.bin conv=fsync,notrunc bs=$sectorSize seek=$((secondOffset - partitionOffset))
        cp -v Tow-Boot.$variant.bin $out/binaries/
        )
      ''}
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
    ] ++ [
      #
      # eMMC woes fixes
      # ---------------
      #
      # Ensures eMMC nodes are present in SPL FDT.
      #
      (fetchpatch {
        url = "https://source.denx.de/u-boot/u-boot/-/commit/f8b36089af26c3596a8b3796af336cee42cc1757.patch";
        sha256 = "sha256-iFqR5CJ/X0Fz41Ta3kcZW48Kcm9mI4m5bAcp66PkNU0=";
      })
      #
      # Unbreaks eMMC for some usage.
      # First two patches are changes needed to apply the series.
      #
      (fetchpatch {
        url = "https://source.denx.de/u-boot/u-boot/-/commit/40e6f52454fc9adb6269ef8089c1fd2ded85fee8.patch";
        sha256 = "sha256-RGBfAR8YC3kY3/2C4cFQR59DtMvYDUdwE6++0jGPNi0=";
      })
      (fetchpatch {
        url = "https://source.denx.de/u-boot/u-boot/-/commit/022f552704b6467966e4fad39c85a6aca9204c94.patch";
        sha256 = "sha256-mDWlJQQjQykb9kzIKZYEBI2Ktdpgc7LZyWspvb2F62w=";
      })
      (fetchpatch {
        # https://patchwork.ozlabs.org/project/uboot/cover/20220116201814.11672-1-alpernebiyasak@gmail.com/
        url = "https://patchwork.ozlabs.org/series/281327/mbox/";
        sha256 = "sha256-gjHwZWIPUzWMUk2+7Mhd4XJuorBluVL9J9LaO9fUaKw=";
      })
    ] ++ patches;
  } // removeAttrs args [ "postPatch" "postInstall" "extraConfig" "patches" ]);

  firmware = firmware' "noenv";
  firmwareSPI = firmware' "spi";
in
firmware.mkOutput ''
  cp --no-preserve=mode -rvt $out/ ${firmware}/*
  ${lib.optionalString withSPI ''
    cp --no-preserve=mode -rvt $out/ ${firmwareSPI}/*
  ''}
  cp -rv ${baseImage}/*.img $out/shared.disk-image.img
  ${lib.optionalString withSPI ''
  cp -rv ${spiInstallerImage}/*.img $out/spi.installer.img
  ''}
''
