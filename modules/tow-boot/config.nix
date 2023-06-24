{ config, lib, ... }:

let
  inherit (lib)
    mkDefault
    mkIf
    toHexString
  ;

  inherit (config.Tow-Boot)
    variant
    releaseNumber
    releaseIdentifier
    withLogo
  ;

  towBootIdentifier = "${releaseNumber}${releaseIdentifier}";

  # Not actually configurable. This is a constant in Tow-Boot.
  # Changing this will require handling the migration to a larger size.
  envSizeInKiB = 128;
  envSize = envSizeInKiB * 1024;
  envSPIOffset = config.hardware.SPISize - envSize;

  withMMCBoot = config.hardware.mmcBootIndex != null;
in
{
  Tow-Boot.config = [
    (helpers: with helpers; {
      # Identity
      # --------

      IDENT_STRING = freeform ''"${towBootIdentifier} [variant: ${variant}]"'';

      # Behaviour
      # ---------

      # Boot menu and default boot configuration

      TOW_BOOT_MENU = lib.mkIf (!config.Tow-Boot.buildUBoot) yes;

      # Gives *some* time for the user to act.
      # Though an already-knowledgeable user will know they can use the key
      # before the message is shown.
      # Conversely, CTRL+C can cancel the default boot, showing the menu as
      # expected In reality, this gives us MUCH MORE slop in the time window
      # than 2 second.
      BOOTDELAY = freeform "2";

      # 27 is ESCAPE
      AUTOBOOT_MENUKEY = freeform "27";

      # So we'll fake that using CTRL+C is what we want...
      # It's only a side-effect.
      AUTOBOOT_PROMPT =
        let
          reset = "\\e[0m";
          bright = "\\e[1m";
        in
        lib.mkIf (!config.Tow-Boot.buildUBoot) (
          freeform ''"${reset}Please press [${bright}ESCAPE${reset}] or [${bright}CTRL+C${reset}] to enter the boot menu."''
        )
      ;

      # And this ends up causing the menu to be used on ESCAPE (or CTRL+C)
      AUTOBOOT_USE_MENUKEY = yes;

      # Additional commands
      CMD_BDI = yes;
      CMD_CLS = yes;
      CMD_SETEXPR = yes;
      CMD_PAUSE = lib.mkIf (!config.Tow-Boot.buildUBoot) yes;
      CMD_POWEROFF = lib.mkDefault yes;
      CMD_NVEDIT_INDIRECT =
        lib.mkIf (lib.versionAtLeast config.Tow-Boot.uBootVersion "2022.07") yes
      ;

      # Looks
      # -----

      # Ensures white text on black background
      SYS_WHITE_ON_BLACK = yes;

      # Ensures we're not using Truetype
      CONSOLE_TRUETYPE = no;
      CONSOLE_TRUETYPE_NIMBUS = no;
    })
    (mkIf withMMCBoot (helpers: with helpers; {
      # Needed for all builds of a target supporting mmcboot.
      # This is because *any other build* needs to be able to address mmc boot partitions.
      SUPPORT_EMMC_BOOT = yes;
    }))
    (helpers: with helpers; {
      # Environment
      # -----------

      # This is used during runtime, not only for saving.
      ENV_SIZE = freeform "0x${toHexString envSize}";

      ENV_IS_IN_EEPROM = mkDefault no;
      ENV_IS_IN_EXT4 = mkDefault no;
      ENV_IS_IN_FAT = mkDefault no;
      ENV_IS_IN_FLASH = mkDefault no;
      ENV_IS_IN_MMC = mkDefault no;
      ENV_IS_IN_NAND = mkDefault no;
      ENV_IS_IN_NVRAM = mkDefault no;
      ENV_IS_IN_ONENAND = mkDefault no;
      ENV_IS_IN_REMOTE = mkDefault no;
      ENV_IS_IN_SPI_FLASH = mkDefault no;
      ENV_IS_IN_UBI = mkDefault no;
      ENV_IS_NOWHERE = mkDefault no;
      SPL_ENV_SUPPORT = mkDefault no;
      TPL_ENV_SUPPORT = mkDefault no;
      TPL_ENV_IS_NOWHERE = mkDefault no;
      SPL_ENV_IS_NOWHERE = mkDefault no;
    })
    (mkIf (variant == "noenv" || variant == "boot-installer") (helpers: with helpers; {
      ENV_IS_NOWHERE = yes;
      TPL_ENV_IS_NOWHERE = option yes;
      SPL_ENV_IS_NOWHERE = option yes;
    }))
    (mkIf ((!config.Tow-Boot.buildUBoot) && variant == "boot-installer") (helpers: with helpers; {
      TOW_BOOT_PREDICTABLE_BOOT_PREFER_EXTERNAL = yes;
      TOW_BOOT_PREDICTABLE_BOOT_PREFER_INTERNAL = no;
    }))
    (mkIf (variant == "mmcboot") (helpers: with helpers; {
      # TODO: Explore options for storing env in mmcboot partition.
      ENV_IS_NOWHERE = yes;
      TPL_ENV_IS_NOWHERE = option yes;
      SPL_ENV_IS_NOWHERE = option yes;
    }))
    (mkIf (variant == "spi") (helpers: with helpers; {
      ENV_IS_IN_SPI_FLASH = yes;
      ENV_SECT_SIZE = freeform "0x2000";
      # Not the actual address
      ENV_ADDR  =  freeform "0x0";
      # The actual address
      ENV_OFFSET =  freeform "0x${toHexString envSPIOffset}";
    }))

    # Logo handling
    # -------------

    (mkIf withLogo (helpers: with helpers; {
      VIDEO_LOGO = yes;
      CMD_BMP = yes;
      SPLASHIMAGE_GUARD = yes;
      SPLASH_SCREEN = yes;
      SPLASH_SCREEN_ALIGN = yes;
      VIDEO_BMP_GZIP = yes;
      BMP_16BPP = yes;
      BMP_24BPP = yes;
      BMP_32BPP = yes;
      SPLASH_SOURCE = no;
    }))
  ];
}
