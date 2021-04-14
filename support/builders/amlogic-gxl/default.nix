{ buildTowBoot, gxlimg }:

# Recognizable by the use of `aml_encrypt_gxl`
#{ FIPDIR, ... } @ args: buildTowBoot ({
{ defconfig, FIPDIR, postPatch ? "", postInstall ? "", ... } @ args:

buildTowBoot ({
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
} // args)
