{
  device = {
    manufacturer = "PINE64";
    name = "ROCK64";
    identifier = "pine64-rock64";
    productPageURL = "https://www.pine64.org/rock64/";
  };

  hardware = {
    soc = "rockchip-rk3328";
    SPISize = 16 * 1024 * 1024; # 16 MiB
  };

  Tow-Boot = {
    defconfig = "rock64-rk3328_defconfig";
    uBootVersion = "2024.10";
    buildUBoot = true;
  };
}
