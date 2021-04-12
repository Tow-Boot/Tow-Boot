{ systems
, runCommandNoCC
, dosfstools
, gptfdisk
, libfaketime
, mtools
, util-linux
, vboot_reference
, writeText
, xxd
}:

let
  inherit (systems) aarch64;
  inherit (aarch64.nixpkgs)
    raspberrypi-armstubs
    raspberrypifw
  ;

  build = args: aarch64.buildTowBoot ({
    meta.platforms = ["aarch64-linux"];
    filesToInstall = ["u-boot.bin"];
    patches = [
      ./0001-configs-rpi-allow-for-bigger-kernels.patch
    ];
    # The necessary implementation is not provided by U-Boot.
    withPoweroff = false;
    # The TTF-based console somehow crashes the Pi.
    withTTF = false;
  } // args);

  raspberryPi-3 = build { defconfig = "rpi_3_defconfig"; };
  raspberryPi-4 = build { defconfig = "rpi_4_defconfig"; };

  config = writeText "config.txt" ''
    [pi3]
    kernel=tow-boot-rpi3.bin

    [pi4]
    kernel=tow-boot-rpi4.bin
    enable_gic=1
    armstub=armstub8-gic.bin
    disable_overscan=1

    [all]
    arm_64bit=1
    enable_uart=1
    avoid_warnings=1
  '';

  disk-image = runCommandNoCC "tow-boot-raspberryPi-aarch64-${raspberryPi-3.version}" {
    partitionSize = 32/*MiB*/ * 1024 * 1024 / 512; # in Sectors
    padding = 16/*MiB*/ * 1024 * 1024 / 512; # in Sectors
    partitionOffset = 2048; # in Sectors

    # "Linux reserved" partition type
    partType = "8DA63339-0007-60C0-C436-083AC8230908";

    # An arbitrary partition UUID for reproducible builds.
    partUUID = "CE8F2026-17B1-4B5B-88F3-3E239F8BD3D8";

    nativeBuildInputs = [
      dosfstools
      gptfdisk
      libfaketime
      mtools
      util-linux
      vboot_reference
      xxd
    ];
  } ''
    echo ":: Building firmware partition"
    mkdir firmware-filesystem
    (cd firmware-filesystem
      cp -v ${config} config.txt
      cp -v ${raspberryPi-3}/u-boot.bin tow-boot-rpi3.bin
      cp -v ${raspberryPi-4}/u-boot.bin tow-boot-rpi4.bin
      cp -v ${raspberrypi-armstubs}/armstub8-gic.bin armstub8-gic.bin
      cp -v ${raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-4-b.dtb bcm2711-rpi-4-b.dtb
    )
    (cd ${raspberrypifw}/share/raspberrypi/boot
      cp -v bootcode.bin fixup*.dat start*.elf $NIX_BUILD_TOP/firmware-filesystem/
    )

    echo $partitionSize
    fallocate -l $((partitionSize * 512)) firmware-partition.img
    faketime "1970-01-01 00:00:00" \
      mkfs.vfat \
        -i "0x3e239f8b" \
        -n "TOW-BOOT-FIRM" \
        firmware-partition.img

    (cd firmware-filesystem
      mcopy -psvm -i $NIX_BUILD_TOP/firmware-partition.img ./* ::
    )
    fsck.vfat -vn firmware-partition.img

    echo ":: Building disk image"

    (PS4=" $ "; set -x
      fallocate -l $((partitionSize*512 + partitionOffset*512 + 32*512 + padding*512)) $out
      cgpt create $out
      cgpt add -b $partitionOffset -s $partitionSize -l "Firmware (Tow-Boot)" -t $partType -u $partUUID $out
      cgpt boot -p $out
      sgdisk --hybrid=1:EE $out
      # Change the partition type to 0x0c; gptfdisk will default to 0x83 here.
      echo '000001c2: 0c' | xxd -r - $out
      sgdisk --print-mbr $out
      cgpt show -v $out
    )

    echo ":: Flashing partition"
    (PS4=" $ "; set -x
      dd bs=512 if=firmware-partition.img of=$out seek=$partitionOffset
    )
  '';
in
{
  #
  # Raspberry Pi
  # -------------
  #
  raspberryPi-aarch64 = runCommandNoCC "tow-boot-raspberryPi-aarch64-${raspberryPi-3.version}" {
  } ''
    mkdir -p $out
    (cd $out
      cp -v ${raspberryPi-3}/u-boot.bin tow-boot-rpi3.bin
      cp -v ${raspberryPi-4}/u-boot.bin tow-boot-rpi4.bin
      cp -v ${disk-image} disk-image.img
    )
  '';

}
