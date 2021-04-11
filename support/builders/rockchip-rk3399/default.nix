{ buildTowBoot, TF-A }:

# For Rockchip RK3399 based hardware
{ defconfig, postPatch ? "", postInstall ? "" }:

buildTowBoot {
  inherit defconfig;
  extraMeta.platforms = ["aarch64-linux"];
  BL31 = "${TF-A}/bl31.elf";
  filesToInstall = [
    ".config"
    "u-boot.itb"
    "idbloader.img"
  ];

  postPatch = ''
    patchShebangs arch/arm/mach-rockchip/
  '' + postPatch;

  postInstall = ''
    tools/mkimage -n rk3399 -T rkspi -d tpl/u-boot-tpl-dtb.bin:spl/u-boot-spl-dtb.bin spl.bin
    cat <(dd if=spl.bin bs=512K conv=sync) u-boot.itb > $out/u-boot.spiflash.bin
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
}

