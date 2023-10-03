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

  # TODO are these values correct also for rk3588?
  firmwareMaxSize = 4 * 1024 * 1024; # MiB in bytes
  partitionOffset = 64; # in sectors
  secondOffset = 16384; # in sectors
  sectorSize = 512;

  anyRockchip = lib.any (v: v) [cfg.rockchip-rk3399.enable cfg.rockchip-rk3588.enable];
  isPhoneUX = config.Tow-Boot.phone-ux.enable;
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
      rockchip-rk3588.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable when SoC is Rockchip RK3588";
        internal = true;
      };
    };
  };

  config = mkMerge [
    {
      hardware.socList = [
        "rockchip-rk3399"
	"rockchip-rk3588"
      ];
    }
    (mkIf cfg.rockchip-rk3399.enable {
      system.system = "aarch64-linux";
      Tow-Boot = {
        config = [
          (helpers: with helpers; {
            # SPI boot Support
            MTD = yes;
            DM_MTD = yes;
            SPI_FLASH_SFDP_SUPPORT = yes;
            SPL_DM_SPI = yes;
            SPL_SPI_FLASH_TINY = no;
            SPL_SPI_FLASH_SFDP_SUPPORT = yes;
            SYS_SPI_U_BOOT_OFFS = freeform ''0x80000''; # 512K
            SPL_DM_SEQ_ALIAS = yes;
          })
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
    (mkIf cfg.rockchip-rk3588.enable {
      system.system = "aarch64-linux";
      Tow-Boot = {
        config = [
          (helpers: with helpers; {
	  # TODO do we need these when implementing the spi variant?
          #   # SPI boot Support
          #   MTD = yes;
          #   DM_MTD = yes;
          #   SPI_FLASH_SFDP_SUPPORT = yes;
          #   SPL_DM_SPI = yes;
          #   SPL_SPI_FLASH_TINY = no;
          #   SPL_SPI_FLASH_SFDP_SUPPORT = yes;
          #   SYS_SPI_U_BOOT_OFFS = freeform ''0x80000''; # 512K
          #   SPL_DM_SEQ_ALIAS = yes;
	    SYS_WHITE_ON_BLACK = lib.mkForce no;
          })
        ];
	# TODO does it make sense also for rk3588?
        firmwarePartition = {
            offset = partitionOffset * 512; # 32KiB into the image, or 64 × 512 long sectors
            length = firmwareMaxSize + (secondOffset * sectorSize); # in bytes
          }
        ;
        builder = {
          additionalArguments = let
	    # FIXME not the best place to put this
	    rkbin = builtins.fetchTarball {
	      url = "https://gitlab.collabora.com/hardware-enablement/rockchip-3588/rkbin/-/archive/master/rkbin-master.tar.gz";
	      sha256 = "0bckv8xv2m4hg5djyv0xbxj96lryvhbyac5qx2m1v0617m15rd2p";
	    };
	  in {
            BL31 = "${rkbin}/bin/rk35/rk3588_bl31_v1.27.elf";
	    ROCKCHIP_TPL = "${rkbin}/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2736MHz_v1.08.bin";
            inherit
              firmwareMaxSize
              partitionOffset
              secondOffset
              sectorSize
            ;
          };
	  # TODO add "spi" variant
          installPhase = ''
              echo ":: Preparing single file firmware image for shared storage..."
              (PS4=" $ "; set -x
              dd if=idbloader.img of=Tow-Boot.$variant.bin conv=fsync,notrunc bs=$sectorSize seek=$((partitionOffset - partitionOffset))
              dd if=u-boot.itb    of=Tow-Boot.$variant.bin conv=fsync,notrunc bs=$sectorSize seek=$((secondOffset - partitionOffset))
              cp -v Tow-Boot.$variant.bin $out/binaries/
              )
            '';
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
