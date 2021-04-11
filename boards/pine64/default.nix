{ allwinnerA64, rockchipRK399 }:

{
  pine64-pineA64LTS = allwinnerA64 { defconfig = "pine64-lts_defconfig"; };
  pine64-pinebookA64 = allwinnerA64 { defconfig = "pinebook_defconfig"; };
  pine64-pinebookPro = rockchipRK399 { defconfig = "pinebook-pro-rk3399_defconfig"; };
}
