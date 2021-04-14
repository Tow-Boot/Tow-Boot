{ amlogicFirmware, amlogicGXL }:

{
  libreComputer-amlS805xAc = amlogicGXL {
    defconfig = "libretech-ac_defconfig";
    FIPDIR = "${amlogicFirmware}/lafrite";
  };
}
