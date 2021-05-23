{ lib, buildTowBoot, gxlimg, imageBuilder, runCommandNoCC, spiInstallerPartitionBuilder }:

# Recognizable by the use of `aml_encrypt_gxl`
{ defconfig, FIPDIR, postPatch ? "", postInstall ? "", withSPI ? false, ... } @ args:

let
  partitionOffset = 1;
  sectorSize = 512;
  firmwareMaxSize = imageBuilder.size.MiB 4;

  firmwarePartition = imageBuilder.firmwarePartition {
    inherit sectorSize;
    partitionOffset = partitionOffset; # in sectors
    partitionSize = firmwareMaxSize; # in bytes
    firmwareFile = "${firmware}/u-boot.bin";
  };

  baseImage' = extraPartitions: imageBuilder.diskImage.makeMBR {
    name = "disk-image";
    diskID = "01234567";
    # Align on 512 sector sizes.
    # This is not for the actual partitions for the end-user, only so we
    # are able to make the first partition start at sector 0x01
    alignment = 512;

    partitions = [
      firmwarePartition
    ] ++ extraPartitions;
  };

  baseImage = baseImage' [];
  spiInstallerImage = baseImage' [
    (spiInstallerPartitionBuilder {
      inherit defconfig;
      firmware = "${firmware}/u-boot.bin";
    })
  ];

  firmware = buildTowBoot ({
    meta.platforms = ["aarch64-linux"];

    nativeBuildInputs = [
      gxlimg
    ];

    postBuild = ''
      echo ":: Merging with firmware blobs"
      (PS4=" $ "; set -x
      # Sign BL2
      python3 $FIPDIR/acs_tool.py $FIPDIR/bl2.bin ./bl2_acs.bin $FIPDIR/acs.bin 0
      sh $FIPDIR/blx_fix.sh \
        ./bl2_acs.bin \
        ./tmp.zero \
        ./tmp.bl2.zero.bin \
        $FIPDIR/bl21.bin \
        ./tmp.bl21.zero.bin \
        ./bl2_new.bin \
        bl2
      gxlimg -t bl2 -s bl2_new.bin bl2.bin.enc

      # Sign Bl3*
      sh $FIPDIR/blx_fix.sh \
        $FIPDIR/bl30.bin \
        ./tmp.zero \
        ./tmp.bl30.zero.bin \
        $FIPDIR/bl301.bin \
        ./tmp.bl301.zero.bin \
        ./bl30_new.bin \
        bl30
      gxlimg -t bl3x -c bl30_new.bin     bl30.bin.enc
      gxlimg -t bl3x -c $FIPDIR/bl31.img bl31.img.enc

      # Encrypt U-Boot
      gxlimg -t bl3x -c u-boot.bin u-boot.bin.enc
      gxlimg -t fip \
        --bl2 ./bl2.bin.enc \
        --bl30 ./bl30.bin.enc \
        --bl31 ./bl31.img.enc \
        --bl33 ./u-boot.bin.enc \
        ./gxl-boot.bin
      mv -v gxl-boot.bin u-boot.bin
      )

      echo ":: Making USB boot files"
      (PS4=" $ "; set -x
      dd if=u-boot.bin of=u-boot.bin.usb.bl2 bs=49152 count=1
      dd if=u-boot.bin of=u-boot.bin.usb.tpl skip=49152 bs=1
      )
    '';

    filesToInstall = [ "u-boot.bin" "u-boot.bin.usb.bl2" "u-boot.bin.usb.tpl" ];
  } // args);
in
firmware.mkOutput ''
  cp -rv ${baseImage}/*.img $out/disk-image.img
  ${lib.optionalString withSPI ''
  cp -rv ${spiInstallerImage}/*.img $out/spi-installer.img
  ''}
''
