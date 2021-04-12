{ buildTowBoot, TF-A, GPTDiskImageBuilder }:

# For Rockchip RK3399 based hardware
{ defconfig, postPatch ? "", postInstall ? "", ... } @ args:

let
  # Currently 1.1MiB... Let's keep A LOT of room on hand.
  firmwareMaxSize = 4 * 1024 * 1024; # MiB in bytes
  partitionOffset = 64; # in sectors
  secondOffset = 16384; # in sectors
  sectorSize = 512;
  baseImage = GPTDiskImageBuilder {
    partitionOffset = partitionOffset; # in sectors
    partitionSize = firmwareMaxSize + (secondOffset * sectorSize); # in bytes
  };
in
buildTowBoot ({
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
    cat <(dd if=spl.bin bs=512K conv=sync) u-boot.itb > $out/firmware.spiflash.bin
    )

    echo ":: Preparing single file firmware image for shared storage..."
    (PS4=" $ "; set -x
    dd if=idbloader.img of=firmware.shared.img conv=fsync,notrunc bs=$sectorSize seek=$((partitionOffset - partitionOffset))
    dd if=u-boot.itb    of=firmware.shared.img conv=fsync,notrunc bs=$sectorSize seek=$((secondOffset - partitionOffset))
    cp -v firmware.shared.img $out/
    )

    echo ":: Preparing GPT image with embedded firmware..."
    (PS4=" $ "; set -x
    cat ${baseImage} > $out/disk-image.img
    dd if=firmware.shared.img of=$out/disk-image.img bs=512 seek=$partitionOffset conv=notrunc
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
    CONFIG_SYS_SPI_U_BOOT_OFFS=0x80000
    CONFIG_SPL_DM_SEQ_ALIAS=y
  '';
} // args)
