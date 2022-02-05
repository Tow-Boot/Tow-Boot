{
  imports = [
    ../libreComputer-rocRk3399Pc
  ];

  device = {
    identifier = "libreComputer-rocRk3399PcMezzanine";
  };

  Tow-Boot = {
    defconfig = "roc-pc-mezzanine-rk3399_defconfig";
  };
}
