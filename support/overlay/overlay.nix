final: super:

let
  inherit (final) lib;
in
{
  Tow-Boot = rec {
    # A reference to the package set.
    nixpkgs = final;

    systems =
      let
        crossPackageSets = {
          aarch64-linux = final.pkgsCross.aarch64-multiplatform;
          armv7l-linux  = final.pkgsCross.armv7l-hf-multiplatform;
          i686-linux    =
            if final.system == "x86_64-linux"
            then final.pkgsi686Linux
            else final.pkgsCross.gnu32
          ;
          x86_64-linux  = final.pkgsCross.gnu64;
        };

        pkgsFor = wanted:
          if final.system == wanted then final
          else crossPackageSets.${wanted}
        ;
        applyOverlay = wanted: ((pkgsFor wanted).extend(import ./overlay.nix)).Tow-Boot;
      in
    {
      # Applies this overlay on top of `pkgsCross` components we actually want.
      # `pkgs.extend()` does not apply the overlay on these other pkgs sets.
      aarch64 = applyOverlay "aarch64-linux";
      armv7l  = applyOverlay  "armv7l-linux";
      i686    = applyOverlay    "i686-linux";
      x86_64  = applyOverlay  "x86_64-linux";
    };

    buildTowBoot =
    {
        extraConfig ? ""
      , extraMakeFlags ? []

      # The following options should only be disabled when it breaks a build.
      , withLogo ? true
      , withTTF ? true
      , withPoweroff ? true
      , ...
    # FIXME: I don't actually want to directly use buildUBoot...
    #        but this is a starting point for the nix interface.
    } @ args: final.buildUBoot ({
      src = builtins.fetchGit /Users/samuel/tmp/u-boot/u-boot;
      pname = "tow-boot-${args.defconfig}";
      version = "tbd";
    } // args // {

      # Inject defines for things lacking actual configuration options.
      NIX_CFLAGS_COMPILE = lib.optionals withLogo [
        "-DCONFIG_SYS_VIDEO_LOGO_MAX_SIZE=${toString (1920*1080*4)}"
        "-DCONFIG_VIDEO_LOGO"
      ];

      extraMakeFlags =
        let
          # To produce the bitmap image:
          #     convert input.png -depth 8 -colors 256 -compress none output.bmp
          # This tiny build produces the `.gz` file that will actually be used.
          compressedLogo = final.runCommandNoCC "uboot-logo" {} ''
            mkdir -p $out
            cp ${../../assets/tow-boot-splash.bmp} $out/logo.bmp
            (cd $out; gzip -9 -k logo.bmp)                          
          '';
        in
        lib.optionals withLogo [
          # Even though the build will actively use the compressed bmp.gz file,
          # we have to provide the uncompressed file and file name here.
          "LOGO_BMP=${compressedLogo}/logo.bmp"
        ] ++ extraMakeFlags
      ;

      extraConfig = ''
        # Behaviour
        # ---------

        # Boot menu required for the menu (duh)
        CONFIG_CMD_BOOTMENU=y

        # Boot menu and default boot configuration

        # Gives *some* time for the user to act.
        # Though an already-knowledgeable user will know they can use the key
        # before the message is shown.
        # Conversely, CTRL+C can cancel the default boot, showing the menu as
        # expected In reality, this gives us MUCH MORE slop in the time window
        # than 1 second.
        CONFIG_BOOTDELAY=1

        # This would be escape, but the USB drivers don't really play well and
        # escape doesn't work from the keyboard.
        CONFIG_AUTOBOOT_MENUKEY=27

        # So we'll fake that using CTRL+C is what we want...
        # It's only a side-effect.
        CONFIG_AUTOBOOT_PROMPT="Press CTRL+C for the boot menu."

        # And this ends up causing the menu to be used on CTRL+C (or escape)
        CONFIG_AUTOBOOT_USE_MENUKEY=y

        ${lib.optionalString withPoweroff ''
        # Additional commands
        CONFIG_CMD_CLS=y
        CONFIG_CMD_POWEROFF=y
        ''}

        # Looks
        # -----

        # Ensures white text on black background
        CONFIG_SYS_WHITE_ON_BLACK=y

        ${lib.optionalString withTTF ''
        # Truetype console configuration
        CONFIG_CONSOLE_TRUETYPE=y
        CONFIG_CONSOLE_TRUETYPE_NIMBUS=y
        CONFIG_CONSOLE_TRUETYPE_SIZE=26
        # Ensure the chosen font is used
        CONFIG_CONSOLE_TRUETYPE_CANTORAONE=n
        CONFIG_CONSOLE_TRUETYPE_ANKACODER=n
        CONFIG_CONSOLE_TRUETYPE_RUFSCRIPT=n
        ''}

        ${lib.optionalString withLogo ''
        # For the splash screen
        CONFIG_CMD_BMP=y
        CONFIG_SPLASHIMAGE_GUARD=y
        CONFIG_SPLASH_SCREEN=y
        CONFIG_SPLASH_SCREEN_ALIGN=y
        CONFIG_VIDEO_BMP_GZIP=y
        CONFIG_VIDEO_BMP_LOGO=y
        CONFIG_VIDEO_BMP_RLE8=n
        CONFIG_BMP_16BPP=y
        CONFIG_BMP_24BPP=y
        CONFIG_BMP_32BPP=y
        CONFIG_SPLASH_SOURCE=n
        ''}

        # Additional configuration (if needed)
        ${extraConfig}
      '';
    });
  };
}
