{ config, lib, pkgs, ... }:

{
  device = {
    manufacturer = "NXP";
    name = "i.MX 8QuadMax Multisensory Enablement Kit";
    identifier = "imx8qm-mek";
    productPageURL = "https://www.nxp.com/design/development-boards/i-mx-evaluation-and-development-boards/i-mx-8quadmax-multisensory-enablement-kit-mek:MCIMX8QM-CPU";
  };

  hardware = {
    soc = "nxp-imx8qm";
  };

  Tow-Boot =  {

    uBootVersion = "2022.04";

    # NXP uses it's own u-boot fork
    src = fetchGit {
      url = "https://source.codeaurora.org/external/imx/uboot-imx.git";
      ref = "lf_v2022.04";
    };

    patches = [
      ./0001-Enable-rich-uboot-environment.patch
      ./0002-Fix-uboot-variable-names.patch
    ];

    defconfig = "imx8qm_mek_defconfig";

    useDefaultPatches = true;

    builder = {
      postPatch = ''
        install -m 0644 $BL31/bl31.bin ./
        install -m 0644 $FWDIR/* ./
        install -m 0644 ${pkgs.Tow-Boot.imx8qmOpTee}/tee.bin ./
        echo "IMAGE A35 tee.bin 0xfe000000" >> board/freescale/imx8qm_mek/uboot-container.cfg
      '';

      makeFlags = [ "spl/u-boot-spl.bin" "flash.bin" "-j32"];

      installPhase = ''
        install -m 0644 flash.bin $out/binaries/Tow-Boot.$variant.bin
      '';
    };

    # The display is not used currently
    withLogo = false;
  };
}
