{ lib, buildTowBoot, meson64-tools, imageBuilder, runCommandNoCC, spiInstallerPartitionBuilder }:

let self =
{ FIPDIR, withSPI ? false, ...} @ args':

let
  args = removeAttrs args' (builtins.attrNames (builtins.functionArgs self));

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
    meta.platforms = [ "aarch64-linux" ];
    inherit variant FIPDIR;

    nativeBuildInputs = [
      meson64-tools
    ];

    postBuild = ''
      echo " :: Merging with proprietary components..."
      (PS4=" $ "; set -x
      meson64-pkg --type bl30 --output bl30.pkg $FIPDIR/bl30.bin $FIPDIR/bl301.bin
      meson64-pkg --type bl2 --output bl2.pkg $FIPDIR/bl2.bin $FIPDIR/acs.bin
      meson64-bl30sig --input bl30.pkg --output bl30.30sig
      meson64-bl3sig  --input bl30.30sig --output bl30.3sig
      meson64-bl3sig  --input $FIPDIR/bl31.img --output bl31.3sig
      meson64-bl3sig  --input u-boot.bin --output bl33.3sig
      meson64-bl2sig  --input bl2.pkg --output bl2.2sig
      args=(
        --bl2 bl2.2sig
        --bl30 bl30.3sig
        --bl31 bl31.3sig
        --bl33 bl33.3sig

        --ddrfw1 $FIPDIR/ddr4_1d.fw
        --ddrfw2 $FIPDIR/ddr4_2d.fw
        --ddrfw3 $FIPDIR/ddr3_1d.fw
        --ddrfw4 $FIPDIR/piei.fw
        --ddrfw5 $FIPDIR/lpddr4_1d.fw
        --ddrfw6 $FIPDIR/lpddr4_2d.fw
        --ddrfw7 $FIPDIR/diag_lpddr4.fw
      )
      test -e $FIPDIR/aml_ddr.fw && args+=(--ddrfw8 $FIPDIR/aml_ddr.fw)
      test -e $FIPDIR/lpddr3_1d.fw && args+=(--ddrfw9 $FIPDIR/lpddr3_1d.fw)

      meson64-bootmk --output Tow-Boot.bin "''${args[@]}"
      )
    '';

    installPhase = ''
      cp -v Tow-Boot.bin $out/binaries/Tow-Boot.$variant.bin
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
'';
in self
