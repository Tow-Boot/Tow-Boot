{ lib, buildTowBoot, imageBuilder, runCommandNoCC, spiInstallerPartitionBuilder }:

# For armv7 Allwinner boards
{ defconfig, withSPI ? false, ... } @ args:

let
  sectorSize = 512;
  partitionOffset = 16; # 8KiB in
  firmwareMaxSize = 4 * 1024 * 1024; # MiB in bytes

  firmwarePartition = imageBuilder.firmwarePartition {
    inherit sectorSize;
    partitionOffset = partitionOffset; # in sectors
    partitionSize = firmwareMaxSize; # in bytes
    firmwareFile = "${firmware}/u-boot-sunxi-with-spl.bin";
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
      firmware = "${firmware}/u-boot-sunxi-with-spl.bin";
    })
  ];

  firmware = buildTowBoot ({
    withPoweroff = false; # At least on H3
    meta.platforms = ["armv7l-linux"];
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
