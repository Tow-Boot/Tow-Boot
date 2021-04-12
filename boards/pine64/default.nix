{ allwinnerA64, rockchipRK399, fetchpatch }:

{
  pine64-pineA64LTS = allwinnerA64 { defconfig = "pine64-lts_defconfig"; };
  pine64-pinebookA64 = allwinnerA64 { defconfig = "pinebook_defconfig"; };
  pine64-pinebookPro = rockchipRK399 {
    defconfig = "pinebook-pro-rk3399_defconfig";
    patches = [
      (fetchpatch {
        url = "https://patchwork.ozlabs.org/series/232334/mbox/";
        sha256 = "0abmc82dccwmf8fjg7lyxx33r0dfc9h2hrx5d32sjl6mfj88hkj7";
      })
    ];
  };
}
