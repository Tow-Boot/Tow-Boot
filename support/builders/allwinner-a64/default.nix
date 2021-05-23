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
    meta.platforms = ["aarch64-linux"];
    BL31 = "${TF-A}/bl31.bin";
    filesToInstall = ["u-boot-sunxi-with-spl.bin"];
  } // args);
in
firmware.mkOutput ''
  cp -rv ${baseImage}/*.img $out/disk-image.img
  ${lib.optionalString withSPI ''
  cp -rv ${spiInstallerImage}/*.img $out/spi-installer.img
  ''}
''
