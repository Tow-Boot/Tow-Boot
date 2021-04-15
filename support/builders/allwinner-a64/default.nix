{ lib, buildTowBoot, TF-A, imageBuilder, runCommandNoCC, spiInstallerImageBuilder }:

# For Allwinner A64 and Allwinner A64 compatible based hardware
{ defconfig, withSPI ? false, ... } @ args:

let
  baseImage' = extraPartitions: imageBuilder.diskImage.makeGPT {
    name = "disk-image";
    diskID = "01234567";
    headerHole =
      # Offset the SoC looks at... bs=1024 * seek=8
      (imageBuilder.size.MiB 8) +
      # Actual space the firmware can take
      (imageBuilder.size.MiB 4)
    ;
    postBuild = ''
      dd if=${firmware}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
    '';

    partitions = [
      # No firmware partition here; it's hidden in the space before the GPT.
    ] ++ extraPartitions;
  };

  baseImage = baseImage' [];
  spiInstallerImage = baseImage' [
    (spiInstallerImageBuilder {
      inherit defconfig;
      firmware = "${firmware}/u-boot-sunxi-with-spl.bin";
    })
  ];

  firmware = buildTowBoot ({
    meta.platforms = ["aarch64-linux"];
    BL31 = "${TF-A}/bl31.bin";
    filesToInstall = ["u-boot-sunxi-with-spl.bin"];
  } // args);
in
runCommandNoCC firmware.name {} ''
  mkdir -p "$out"
  cp -rvt $out/ ${firmware}/.config
  cp -rvt $out/ ${firmware}/*
  cp -rv ${baseImage}/*.img $out/disk-image.img
  ${lib.optionalString withSPI ''
  cp -rv ${spiInstallerImage}/*.img $out/spi-installer.img
  ''}
''
