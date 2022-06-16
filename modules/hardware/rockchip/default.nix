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
  ;
  cfg = config.hardware.socs;

  firmwareMaxSize = 4 * 1024 * 1024; # MiB in bytes
  partitionOffset = 64; # in sectors
  secondOffset = 16384; # in sectors
  sectorSize = 512;

  anyRockchip = lib.any (v: v) [cfg.rockchip-rk3399.enable];
  isPhoneUX = config.Tow-Boot.phone-ux.enable;
  withSPI = config.hardware.SPISize != null;
in
{
  options = {
    hardware.socs = {
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
      hardware.socList = [
        "rockchip-rk3399"
      ];
    }
    (mkIf cfg.rockchip-rk3399.enable {
      system.system = "aarch64-linux";
      Tow-Boot = {
        config = [
          (mkIf withSPI (helpers: with helpers; {
            # SPI boot Support
            MTD = yes;
            DM_MTD = yes;
            SPI_FLASH_SFDP_SUPPORT = yes;
            SPL_DM_SPI = yes;
            SPL_SPI_FLASH_TINY = no;
            SPL_SPI_FLASH_SFDP_SUPPORT = yes;
            SPL_SPI_SUPPORT = yes;
            SPL_SPI_FLASH_SUPPORT = yes;
            SPL_SPI_LOAD = yes;
            SYS_SPI_U_BOOT_OFFS = freeform ''0x80000''; # 512K
            SPL_DM_SEQ_ALIAS = yes;
          }))

          (helpers: with helpers; {
            # Not supported on this platform
            CMD_POWEROFF = no;
          })
        ];
        patches = mkMerge [
          [
            ./0001-HACK-efi_runtime-pretend-we-can-t-reset.patch
          ]
          [
            # Ensures eMMC nodes are present in SPL FDT.
            (fetchpatch {
              url = "https://source.denx.de/u-boot/u-boot/-/commit/f8b36089af26c3596a8b3796af336cee42cc1757.patch";
              sha256 = "sha256-iFqR5CJ/X0Fz41Ta3kcZW48Kcm9mI4m5bAcp66PkNU0=";
            })
          ]
          (mkIf ((!versionAtLeast config.Tow-Boot.uBootVersion "2022.01") && (versionAtLeast config.Tow-Boot.uBootVersion "2021.10")) [
            # Required backports for 2021.10, for the next patch.
            (fetchpatch {
              url = "https://source.denx.de/u-boot/u-boot/-/commit/40e6f52454fc9adb6269ef8089c1fd2ded85fee8.patch";
              sha256 = "sha256-RGBfAR8YC3kY3/2C4cFQR59DtMvYDUdwE6++0jGPNi0=";
            })
            (fetchpatch {
              url = "https://source.denx.de/u-boot/u-boot/-/commit/022f552704b6467966e4fad39c85a6aca9204c94.patch";
              sha256 = "sha256-mDWlJQQjQykb9kzIKZYEBI2Ktdpgc7LZyWspvb2F62w=";
            })
          ])
          (mkIf ((versionAtLeast config.Tow-Boot.uBootVersion "2021.10")) [
            # Fix eMMC regressions.
            (fetchpatch {
              # https://patchwork.ozlabs.org/project/uboot/cover/20220116201814.11672-1-alpernebiyasak@gmail.com/
              url = "https://patchwork.ozlabs.org/series/281327/mbox/";
              sha256 = "sha256-gjHwZWIPUzWMUk2+7Mhd4XJuorBluVL9J9LaO9fUaKw=";
            })
          ])
        ];
        firmwarePartition = {
            offset = partitionOffset * 512; # 32KiB into the image, or 64 × 512 long sectors
            length = firmwareMaxSize + (secondOffset * sectorSize); # in bytes
          }
        ;
        builder = {
          additionalArguments = {
            BL31 = "${pkgs.Tow-Boot.armTrustedFirmwareRK3399}/bl31.elf";
            inherit
              firmwareMaxSize
              partitionOffset
              secondOffset
              sectorSize
            ;
          };
          installPhase = mkMerge [
            (mkIf (variant == "spi") ''
              echo ":: Preparing image for SPI flash..."
              (PS4=" $ "; set -x
              tools/mkimage -n rk3399 -T rkspi -d tpl/u-boot-tpl-dtb.bin:spl/u-boot-spl-dtb.bin spl.bin
              # 512K here is 0x80000 CONFIG_SYS_SPI_U_BOOT_OFFS
              cat <(dd if=spl.bin bs=512K conv=sync) u-boot.itb > $out/binaries/Tow-Boot.$variant.bin
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
