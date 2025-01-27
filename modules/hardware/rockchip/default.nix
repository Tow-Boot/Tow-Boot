{ config, lib, pkgs, ... }:

let
  inherit (pkgs)
    fetchpatch
  ;
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
    versionOlder
    versionAtLeast
  ;
  inherit (config.Tow-Boot)
    variant
    uBootVersion
  ;
  cfg = config.hardware.socs;
  withSPI = config.hardware.SPISize != null;

  firmwareMaxSize = 4 * 1024 * 1024; # MiB in bytes
  partitionOffset = 64; # in sectors
  secondOffset = 16384; # in sectors
  sectorSize = 512;

   rockchipSOCs = [
    "rockchip-rk3328"
    "rockchip-rk3399"
  ];

  anyRockchip = lib.any (soc: config.hardware.socs.${soc}.enable) rockchipSOCs;
  isPhoneUX = config.Tow-Boot.phone-ux.enable;
  useSpi2K4Kworkaround = cfg.rockchip-rk3399.enable;
  useSpiSDLayout = cfg.rockchip-rk3328.enable;
  chipName =
         if cfg.rockchip-rk3328.enable then "rk3328"
    else if cfg.rockchip-rk3399.enable then "rk3399"
    else throw "chipName needs to be defined for SoC."
  ;
in
{
  options = {
    hardware.socs = {
      rockchip-rk3328.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is Rockchip RK3328";
        internal = true;
      };
      rockchip-rk3399.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is Rockchip RK3399";
        internal = true;
      };
    };
  };

  config = mkMerge [
    {
      hardware.socList = rockchipSOCs;
    }
    (mkIf anyRockchip {
      system.system = "aarch64-linux";
      Tow-Boot = {
        config = mkIf withSPI [
          (helpers: with helpers; {
            # SPI boot Support
            MTD = yes;
            DM_MTD = yes;
            ROCKCHIP_SPI_IMAGE = mkIf (versionAtLeast uBootVersion "2022.10") yes;
            SPI_FLASH_SFDP_SUPPORT = yes;
            SPL_DM_SPI = yes;
            SPL_SPI_FLASH_SUPPORT = yes;
            SPL_SPI_LOAD = yes;
            SPL_SPI = yes;
            SPL_SPI_FLASH_TINY = no;
            SPL_SPI_FLASH_SFDP_SUPPORT = yes;
            # NOTE: Some boards may have a different value:
            #   ~/tmp/u-boot/u-boot $ grep -l -R 'u-boot,spl-payload-offset' arch/*/dts/rk*.dts*
            #    arch/arm/dts/rk3368-lion-haikou-u-boot.dtsi
            #    arch/arm/dts/rk3399-gru-u-boot.dtsi
            #    arch/arm/dts/rk3399-puma-haikou-u-boot.dtsi
            # Not an issue currently.
            SYS_SPI_U_BOOT_OFFS = freeform ''0x80000''; # 512K
            SPL_DM_SEQ_ALIAS = yes;
          })
        ];
        firmwarePartition = {
            offset = partitionOffset * sectorSize; # 32KiB into the image, or 64 × 512 long sectors
            length = firmwareMaxSize + (secondOffset * sectorSize); # in bytes
          }
        ;
        builder = {
          additionalArguments = {
            inherit
              firmwareMaxSize
              partitionOffset
              secondOffset
              sectorSize
            ;
          };
          installPhase = mkMerge [
            (mkIf (variant == "spi" && useSpi2K4Kworkaround) ''
              echo ":: Preparing image for SPI flash (2K/4K workaround)..."
              (PS4=" $ "; set -x
              tools/mkimage \
                -n ${chipName} \
                -T rkspi \
                -d tpl/u-boot-tpl-dtb.bin:spl/u-boot-spl-dtb.bin spl.bin
              # 512K here is 0x80000 CONFIG_SYS_SPI_U_BOOT_OFFS
              cat <(dd if=spl.bin bs=512K conv=sync) u-boot.itb > $out/binaries/Tow-Boot.$variant.bin
              )
            '')
            (mkIf (variant == "spi" && useSpiSDLayout) ''
              echo ":: Preparing image for SPI flash (SD layout)..."
              (PS4=" $ "; set -x
              dd if=idbloader.img of=Tow-Boot.$variant.bin conv=fsync,notrunc bs=$sectorSize seek=0
              # 0x80000 here is CONFIG_SYS_SPI_U_BOOT_OFFS
              dd if=u-boot.itb    of=Tow-Boot.$variant.bin conv=fsync,notrunc bs=$sectorSize seek=$((0x80000 / sectorSize))
              cp -v Tow-Boot.$variant.bin $out/binaries/
              )
            '')
            (mkIf (variant != "spi") ''
              echo ":: Preparing single file firmware image for shared storage..."
              (PS4=" $ "; set -x
              dd if=idbloader.img of=Tow-Boot.$variant.bin conv=fsync,notrunc bs=$sectorSize seek=$((partitionOffset - partitionOffset))
              dd if=u-boot.itb    of=Tow-Boot.$variant.bin conv=fsync,notrunc bs=$sectorSize seek=$((secondOffset - partitionOffset))
              cp -v Tow-Boot.$variant.bin $out/binaries/
              )
            '')
          ];
        };
      };
    })

    (mkIf (anyRockchip) {
      Tow-Boot = {
        config = [
          (helpers: with helpers; {
            CMD_POWEROFF = yes;
            SYSRESET_CMD_POWEROFF = yes;
            VIDEO = yes;
            DISPLAY = yes;
            VIDEO_ROCKCHIP = yes;
            DISPLAY_ROCKCHIP_HDMI = yes;
            PHY_ROCKCHIP_INNO_HDMI = yes;
            BOOTSTD = lib.mkForce yes;
            BOOTSTD_DEFAULTS = lib.mkForce  yes;
            DISTRO_DEFAULTS = lib.mkForce  no;
            BOOTCOMMAND =  lib.mkForce (freeform ''"bootflow scan"'');
          })
        ];
        builder.postPatch =
          # The baud rate needs to be patched out to match the `CONFIG_BAUDRATE` value,
          # since this `chosen/stdout-path` value serves as the default if no `console=` param exists.
          # I don't know if it's possible with the tooling of U-Boot upstream, but if it is, they should sync that.
          ''
            echo ':: Patching stdout baud rate in rockchip device trees'
            (PS4=" $ "
            for f in arch/arm/dts/*rk3*.dts*; do
              (set -x
              sed -i -e 's/serial2:1500000n8/serial2:115200n8/' "$f"
              )
            done
            )
          ''
        ;
      };
    })

    (mkIf cfg.rockchip-rk3328.enable {
      Tow-Boot.builder.additionalArguments.BL31 = "${pkgs.Tow-Boot.armTrustedFirmwareRK3328}/bl31.elf";
    })

    (mkIf cfg.rockchip-rk3399.enable {
      Tow-Boot.builder.additionalArguments.BL31 = "${pkgs.Tow-Boot.armTrustedFirmwareRK3399}/bl31.elf";
    })

    # Documentation fragments
    (mkIf (anyRockchip && !isPhoneUX) {
      documentation.sections.installationInstructions =
        lib.mkDefault
        (config.documentation.helpers.genericInstallationInstructionsTemplate {
          startupConflictNote = ''

            > **NOTE**: The SoC startup order for Rockchip systems will
            > prefer *SPI*, then *eMMC*, followed by *SD* last.
            >
            > You may need to prevent default startup sources from being used
            > to install using the Tow-Boot installer image.

          '';
        })
      ;
    })
  ];
}
