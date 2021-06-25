{ allwinnerA64, allwinnerArmv7 }:

{
  orangePi-pc = allwinnerArmv7 {
    boardIdentifier = "orangePi-pc";
    defconfig = "orangepi_pc_defconfig";
  };
  orangePi-zeroPlus2H5 = allwinnerA64 {
    boardIdentifier = "orangePi-zeroPlus2H5";
    defconfig = "orangepi_zero_plus2_defconfig";
    patches = [
      ./0001-sun50i-h5-orangepi-zero-plus2-Enable-USB.patch
    ];
  };
}
