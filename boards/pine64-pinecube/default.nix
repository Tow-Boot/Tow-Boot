{
  device = {
    manufacturer = "PINE64";
    name = "PineCube";
    identifier = "pine64-pinecube";
    productPageURL = "https://www.pine64.org/cube/";
  };

  hardware = {
    soc = "allwinner-s3";
  };

  Tow-Boot = {
    defconfig = "pinecube_defconfig";
    withLogo = false;
  };
}
