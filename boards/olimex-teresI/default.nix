{
  device = {
    manufacturer = "Olimex";
    name = "TERES-I";
    identifier = "olimex-teresI";
  };

  hardware = {
    soc = "allwinner-a64";
  };

  Tow-Boot = {
    defconfig = "teres_i_defconfig";
    # Not available in crust
    # https://github.com/crust-firmware/crust/issues/195
    builder.additionalArguments = {
      SCP = null;
    };
  };
}
