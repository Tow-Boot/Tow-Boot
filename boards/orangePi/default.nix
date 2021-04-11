{ allwinnerA64 }:

{
  orangePi-zeroPlus2H5 = allwinnerA64 {
    defconfig = "orangepi_zero_plus2_defconfig";
    patches = [
      ./0001-sun50i-h5-orangepi-zero-plus2-Enable-USB.patch
    ];
  };
}
