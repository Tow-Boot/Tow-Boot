# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Copyright (c) 2003-2021 Eelco Dolstra and the Nixpkgs/NixOS contributors
# SPDX-FileCopyrightText: Copyright (c) 2019 Ben Wolsieffer <benwolsieffer@gmail.com
# SPDX-FileCopyrightText: Copyright (c) 2021 Samuel Dionne-Riel and respective contributors
#
# This builder function is heavily based off of the ODROID-C2 build from
# Nixpkgs, originally authored by 
#
# Origin: https://github.com/NixOS/nixpkgs/commit/884580982851dee0529f018a0bb351f192e6f1d7

{ buildTowBoot
, imageBuilder
, armTrustedFirmwareS905
, armTrustedFirmwareTools
, amlogicFirmware
, meson-tools
, runCommandNoCC
}:

let
  partitionOffset = 1;
  sectorSize = 512;
  firmwareMaxSize = imageBuilder.size.MiB 4;

  firmwarePartition = imageBuilder.firmwarePartition {
    inherit sectorSize;
    partitionOffset = partitionOffset; # in sectors
    partitionSize = firmwareMaxSize; # in bytes
    firmwareFile = "${firmware}/u-boot-combined.bin";
  };

  baseImage = baseImage' [];
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

    postBuild = ''
      (PS4=" $ "; set -x
      dd if=${firmware}/bl1.bin.hardkernel of=$img conv=fsync,notrunc bs=1 count=442
      )
    '';
  };

  firmware = buildTowBoot {
    # Amlogic S905 / GXBB
    # This uses a bespoke build because while it's GXBB, the binaries from the
    # vendor are not as expected.
    defconfig = "odroid-c2_defconfig";

    nativeBuildInputs = [
      armTrustedFirmwareTools
      meson-tools
    ];

    FIPDIR = "${amlogicFirmware}/odroid-c2";
    BL31 = "${armTrustedFirmwareS905}/bl31.bin";

    postBuild = ''
      # BL301 image needs at least 64 bytes of padding after it to place
      # signing headers (with amlbootsig)
      truncate -s 64 bl301.padding.bin
      cat $FIPDIR/bl301.bin bl301.padding.bin > bl301.padded.bin

      # The downstream fip_create tool adds a custom TOC entry with UUID
      # AABBCCDD-ABCD-EFEF-ABCD-12345678ABCD for the BL301 image. It turns out
      # that the firmware blob does not actually care about UUIDs, only the
      # order the images appear in the file. Because fiptool does not know
      # about the BL301 UUID, we would have to use the --blob option, which adds
      # the image to the end of the file, causing the boot to fail. Instead, we
      # take advantage of the fact that UUIDs are ignored and just put the
      # images in the right order with the wrong UUIDs. In the command below,
      # --tb-fw is really --scp-fw and --scp-fw is the BL301 image.
      #
      # See https://github.com/afaerber/meson-tools/issues/3 for more
      # information.
      fiptool create \
        --align 0x4000 \
        --tb-fw $FIPDIR/bl30.bin \
        --scp-fw bl301.padded.bin \
        --soc-fw $BL31 \
        --nt-fw u-boot.bin \
        fip.bin
      cat $FIPDIR/bl2.package fip.bin > boot_new.bin
      amlbootsig boot_new.bin u-boot.img

      # Extract u-boot from the image
      dd if=u-boot.img of=u-boot.bin bs=512 skip=96

      # Ensure we're not accidentally re-using this transient u-boot image
      rm u-boot.img

      # Pick bl1.bin.hardkernel from FIPDIR so it can be installed in filesToInstall.
      cp $FIPDIR/bl1.bin.hardkernel ./

      # Create the .img file to flash from sector 0x01 (bs=512 seek=1)
      # It contains the remainder of bl1.bin.hardkernel and u-boot
      dd if=bl1.bin.hardkernel of=u-boot-combined.bin conv=notrunc bs=512 skip=1 seek=0
      dd if=u-boot.bin         of=u-boot-combined.bin conv=notrunc bs=512 seek=96
    '';

    filesToInstall = [
      "u-boot-combined.bin"
      "bl1.bin.hardkernel"
    ];
    meta.platforms = ["aarch64-linux"];
  };
in
firmware.mkOutput ''
  cp -rv ${baseImage}/*.img $out/disk-image.img
''
