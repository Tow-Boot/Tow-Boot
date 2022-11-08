{
  device = {
    manufacturer = "PINE64";
    name = "PineCube";
    identifier = "pine64-pinecube";
    productPageURL = "https://www.pine64.org/cube/";
  };

  hardware = {
    soc = "allwinner-s3";
    SPISize = 16 * 1024 * 1024; # 128mbit
  };

  Tow-Boot = {
    defconfig = "pinecube_defconfig";
    withLogo = false;
    patches = [
      ./0001-pinecube-enable-SPI-booting-flashing.patch
    ];
  };
}
