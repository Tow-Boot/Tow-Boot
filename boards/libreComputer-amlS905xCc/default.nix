{ config, lib, pkgs, ... }:

{
  device = {
    manufacturer = "Libre Computer";
    name = "Le Potato";
    identifier = "libreComputer-amlS905xAc";
    productPageURL = "https://libre.computer/products/aml-s905x-cc/";
  };

  hardware = {
    soc = "amlogic-s905x";
  };

  Tow-Boot = {
    defconfig = "libretech-cc_defconfig";
    builder.additionalArguments = {
      FIPDIR = "${pkgs.Tow-Boot.amlogicFirmware}/lepotato";
    };
  };
}
