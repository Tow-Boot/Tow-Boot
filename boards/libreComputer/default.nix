{ amlogicFirmware, amlogicGXL, rockchipRK399 }:

{
  libreComputer-amlS805xAc = amlogicGXL {
    defconfig = "libretech-ac_defconfig";
    FIPDIR = "${amlogicFirmware}/lafrite";
    withSPI = true;
  };
  libreComputer-rocRk3399Pc = rockchipRK399 {
    defconfig = "roc-pc-rk3399_defconfig";
    patches = [
      ./0001-rk3399-roc-pc-Configure-SPI-flash-boot-offset.patch
    ];
  };
  libreComputer-rocRk3399PcMezzanine = rockchipRK399 {
    defconfig = "roc-pc-mezzanine-rk3399_defconfig";
    patches = [
      ./0001-rk3399-roc-pc-Configure-SPI-flash-boot-offset.patch
    ];
  };
}
