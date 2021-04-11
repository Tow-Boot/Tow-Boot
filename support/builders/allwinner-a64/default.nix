{ buildTowBoot, TF-A, holeyGPTDiskImageBuilder }:

# For Allwinner A64 and Allwinner A64 compatible based hardware
{ defconfig, ... } @ args:

let
  offset = 8 * 1024; # in bytes... `seek * bs`
  firmwareMaxSize = 4 * 1024 * 1024; # MiB in bytes
  baseImage = holeyGPTDiskImageBuilder {
    pad = (offset + firmwareMaxSize) / 512; # in sectors
  };
in
buildTowBoot ({
  meta.platforms = ["aarch64-linux"];
  BL31 = "${TF-A}/bl31.bin";
  filesToInstall = ["u-boot-sunxi-with-spl.bin"];

  postInstall = ''
    echo ":: Preparing holey GPT image with embedded firmware..."
    (PS4=" $ "; set -x
    cat ${baseImage} > $out/disk-image.img
    dd if=u-boot-sunxi-with-spl.bin of=$out/disk-image.img bs=1024 seek=8 conv=notrunc
    )
  '';
} // args)
