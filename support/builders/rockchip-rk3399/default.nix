{ lib
, buildTowBoot
, TF-A
, imageBuilder
, runCommandNoCC
, writeText
, spiInstallerPartitionBuilder
, rkbin
}:

# For Rockchip RK3399 based hardware
{ postPatch ? ""
, postInstall ? ""
, extraConfig ? ""
, patches ? []
, withSPI ? true
, withProprietaryLoader ? false
, withProprietaryDDR ? false
, MINILOADER_BLOB ? null
, DDR_BLOB ? null
, BL31 ? "${TF-A}/bl31.elf"
, ... } @ args:

if withProprietaryDDR && withProprietaryLoader then
  throw "withProprietaryLoader and withProprietaryDDR are mutually exclusive."
else
if withProprietaryDDR && DDR_BLOB == null then
  throw "DDR_BLOB must be provided when building for r3399 withProprietaryDDR."
else
if withProprietaryLoader && (MINILOADER_BLOB == null || DDR_BLOB == null) then
  throw "MINILOADER_BLOB and DDR_BLOB must be provided when building for r3399 withProprietaryLoader."
else

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

    inherit BL31;
    inherit DDR_BLOB;
    inherit MINILOADER_BLOB;

    postPatch = ''
      patchShebangs arch/arm/mach-rockchip/
    '' + postPatch;

    installPhase = ''
      ${lib.optionalString (variant == "spi") ''
        echo ":: Preparing image for SPI flash..."
        (PS4=" $ "; set -x
        ${if withProprietaryDDR then ''
          echo "ERROR: SPI support for proprietary DDR not supported yet."
          exit 1
        '' else if withProprietaryLoader then ''
          echo "ERROR: SPI support for proprietary loader not supported yet."
          exit 1
          tools/mkimage -n rk3399 -T rkspi -d $DDR_BLOB:$MINILOADER_BLOB spl.bin
        '' else ''
          tools/mkimage -n rk3399 -T rkspi -d tpl/u-boot-tpl-dtb.bin:spl/u-boot-spl-dtb.bin spl.bin
          # 512K here is 0x80000 CONFIG_SYS_SPI_U_BOOT_OFFS
          cat <(dd if=spl.bin bs=512K conv=sync) u-boot.itb > $out/binaries/Tow-Boot.$variant.bin
        ''}
        )
      ''}

      ${lib.optionalString (variant != "spi") ''
        echo ":: Preparing single file firmware image for shared storage..."
        (PS4=" $ "; set -x

        ${if withProprietaryDDR then ''
          tools/mkimage -n rk3399 -T rksd -d $DDR_BLOB Tow-Boot.$variant.bin
          cat spl/u-boot-spl.bin >> Tow-Boot.$variant.bin
          dd if=u-boot.itb    of=Tow-Boot.$variant.bin conv=fsync,notrunc bs=$sectorSize seek=$((secondOffset - partitionOffset))
        '' else if withProprietaryLoader then ''
          echo "ERROR: SD/MMC support for proprietary loader not supported yet."
          exit 1

          # XXX This implementation doesn't actually work
          # stays "stuck" at LoadTrustBL error:-3

          cat > trust.ini <<EOF
            [VERSION]
            MAJOR=1
            MINOR=0
            [BL30_OPTION]
            SEC=0
            [BL31_OPTION]
            SEC=1
            PATH=bl31.elf
            ADDR=0x10000
            [BL32_OPTION]
            SEC=0
            [BL33_OPTION]
            SEC=0
            [OUTPUT]
            PATH=trust.bin
          EOF

          # Prevent accidental use of mainline-based binaries
          rm -f idbloader.img
          rm -f u-boot.itb
          rm -f u-boot.img
          rm -f trust.bin

          tools/mkimage -n rk3399 -T rksd -d $DDR_BLOB idbloader.img
          cat $MINILOADER_BLOB >> idbloader.img
          ${rkbin}/bin/trust_merger --verbose --replace bl31.elf $BL31 trust.ini
          ${rkbin}/bin/loaderimage --pack --uboot ./u-boot-dtb.bin u-boot.img 0x200000

          dd if=idbloader.img of=Tow-Boot.$variant.bin conv=fsync,notrunc bs=$sectorSize seek=$((partitionOffset - partitionOffset))
          # Hardcoded offset for proprietary blobs (booo)
          dd if=u-boot.img    of=Tow-Boot.$variant.bin conv=fsync,notrunc bs=$sectorSize seek=$((0x4000 - partitionOffset))
          dd if=trust.bin     of=Tow-Boot.$variant.bin conv=fsync,notrunc bs=$sectorSize seek=$((0x6000 - partitionOffset))
        '' else ''
          dd if=idbloader.img of=Tow-Boot.$variant.bin conv=fsync,notrunc bs=$sectorSize seek=$((partitionOffset - partitionOffset))
          dd if=u-boot.itb    of=Tow-Boot.$variant.bin conv=fsync,notrunc bs=$sectorSize seek=$((secondOffset - partitionOffset))
        ''}
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
