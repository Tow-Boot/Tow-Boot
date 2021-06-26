{ lib, buildTowBoot, gxlimg, imageBuilder, runCommandNoCC, spiInstallerPartitionBuilder }:

# Recognizable by the use of `aml_encrypt_gxl`
{ FIPDIR, postPatch ? "", postInstall ? "", withSPI ? false, ... } @ args:

let
  partitionOffset = 1;
  sectorSize = 512;
  firmwareMaxSize = imageBuilder.size.MiB 4;

  firmwarePartition = imageBuilder.firmwarePartition {
    inherit sectorSize;
    partitionOffset = partitionOffset; # in sectors
    partitionSize = firmwareMaxSize; # in bytes
    firmwareFile = "${firmware}/binaries/Tow-Boot.noenv.bin";
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
      firmware = firmwareSPI;
    })
  ];

  firmware' = variant: buildTowBoot ({
    meta.platforms = ["aarch64-linux"];
    inherit variant;

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
      mv -v gxl-boot.bin Tow-Boot.bin
      )

      echo ":: Making USB boot files"
      (PS4=" $ "; set -x
      dd if=Tow-Boot.bin of=Tow-Boot.bin.usb.bl2 bs=49152 count=1
      dd if=Tow-Boot.bin of=Tow-Boot.bin.usb.tpl skip=49152 bs=1
      )
    '';

    installPhase = ''
      cp -v Tow-Boot.bin         $out/binaries/Tow-Boot.$variant.bin
      cp -v Tow-Boot.bin.usb.bl2 $out/binaries/Tow-Boot.$variant.usb.bl2
      cp -v Tow-Boot.bin.usb.tpl $out/binaries/Tow-Boot.$variant.usb.tpl
    '';
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
