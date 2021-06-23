{ lib, buildTowBoot, TF-A, imageBuilder, runCommandNoCC, spiInstallerPartitionBuilder }:

# For Allwinner A64 and Allwinner A64 compatible based hardware
{ defconfig, withSPI ? false, ... } @ args:

let
  sectorSize = 512;
  partitionOffset = 16; # 8KiB in
  firmwareMaxSize = 4 * 1024 * 1024; # MiB in bytes

  firmwarePartition = imageBuilder.firmwarePartition {
    inherit sectorSize;
    partitionOffset = partitionOffset; # in sectors
    partitionSize = firmwareMaxSize; # in bytes
    firmwareFile = "${firmware}/binaries/Tow-Boot.noenv.bin";
  };

  baseImage' = extraPartitions: imageBuilder.diskImage.makeGPT {
    name = "disk-image";
    diskID = "01234567";
    partitionEntriesCount = 48;

    partitions = [
      firmwarePartition
    ] ++ extraPartitions;
  };

  baseImage = baseImage' [];
  spiInstallerImage = baseImage' [
    (spiInstallerPartitionBuilder {
      inherit defconfig;
      firmware = "${firmwareSPI}/binaries/Tow-Boot.spi.bin";
    })
  ];

  firmware' = variant: buildTowBoot ({
    meta.platforms = ["aarch64-linux"];
    BL31 = "${TF-A}/bl31.bin";
    installPhase = ''
      cp -v u-boot-sunxi-with-spl.bin $out/binaries/Tow-Boot.$variant.bin
    '';
    inherit variant;
  } // args);

  firmware = firmware' "noenv";
  firmwareSPI = firmware' "spi";
in
firmware.mkOutput ''
  cp --no-preserve=mode -rvt $out/ ${firmware}/*
  ${lib.optionalString withSPI ''
    cp --no-preserve=mode -rvt $out/ ${firmwareSPI}/*
  ''}
  cp -rv ${baseImage}/*.img $out/shared.disk-image.img
  ${lib.optionalString withSPI ''
  cp -rv ${spiInstallerImage}/*.img $out/spi.installer.img
  ''}
''
