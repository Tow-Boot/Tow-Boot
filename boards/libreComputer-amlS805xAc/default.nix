{ lib, pkgs, ... }:

{
  device = {
    manufacturer = "Libre Computer";
    name = "La Frite";
    identifier = "libreComputer-amlS805xAc";
  };

  hardware = {
    soc = "amlogic-s805x";
    SPISize = 128 /* Mbits */ * 1024 * 1024 / 8; # equiv to 16 MiB
  };

  Tow-Boot = {
    defconfig = "libretech-ac_defconfig";
    builder.additionalArguments = {
      FIPDIR = "${pkgs.Tow-Boot.amlogicFirmware}/lafrite";
    };
  };
}
