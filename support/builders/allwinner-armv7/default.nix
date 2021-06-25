{ lib, buildTowBoot, imageBuilder, runCommandNoCC, spiInstallerPartitionBuilder }:

# For armv7 Allwinner boards
{ withSPI ? false, ... } @ args:

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
      firmware = firmwareSPI;
    })
  ];

  firmware' = variant: buildTowBoot ({
    withPoweroff = false; # At least on H3
    meta.platforms = ["armv7l-linux"];
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
