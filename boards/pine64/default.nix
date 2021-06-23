{ Tow-Boot, allwinnerA64, rockchipRK399 }:

{
  pine64-pineA64 = allwinnerA64 {
    defconfig = "pine64_plus_defconfig";
  };
  pine64-pineA64LTS = allwinnerA64 {
    defconfig = "pine64-lts_defconfig";
    withSPI = true;
    SPISize = 16 * 1024 * 1024; # 16 MiB
    patches = [
      ./0001-configs-pine64-lts-Enable-SPI-flash.patch
    ];
  };
  pine64-pinebookA64 = allwinnerA64 { defconfig = "pinebook_defconfig"; };
  pine64-pinebookPro = Tow-Boot.systems.aarch64.callPackage ./pinebook-pro.nix { };
  pine64-rockpro64 = rockchipRK399 {
    defconfig = "rockpro64-rk3399_defconfig";
    patches = [
      ./0001-rockpro64-rk3399-Configure-SPI-flash-boot-offset.patch
    ];
  };
}
