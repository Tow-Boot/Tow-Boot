{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    optionals
    types
  ;
  inherit (config.Tow-Boot)
    uBootVersion
    withLogo
  ;

  evaluatedStructuredConfig = import ../../support/nix/eval-kconfig.nix rec {
    inherit lib;
    inherit (pkgs) path;
    version = config.Tow-Boot.uBootVersion;
    structuredConfig = (config.Tow-Boot.structuredConfigHelper version);
  };

  towBootIdentifier = "${config.Tow-Boot.releaseNumber}${config.Tow-Boot.releaseIdentifier}";
in
{
  options = {
    Tow-Boot.builder = {
      additionalArguments = mkOption {
        type = with types; attrsOf anything;
        default = {};
        description = ''
          Additional arguments to provide to the Nix build environment.

          (Merge semantics are to conflict.)
        '';
      };
      postPatch = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Additional patch phase instructions for the build.

          (Use sparingly.)
        '';
      };
      installPhase = mkOption {
        type = types.lines;
        description = ''
          Platform-specific install instructions.
        '';
      };
      makeFlags = mkOption {
        type = with types; listOf str;
        default = [];
        description = ''
          Additional make flags.
        '';
      };
      buildInputs = mkOption {
        type = with types; listOf package;
        default = [];
        description = ''
          Additional build inputs.
        '';
      };
      nativeBuildInputs = mkOption {
        type = with types; listOf package;
        default = [];
        description = ''
          Additional native build inputs.
        '';
      };
      meta = mkOption {
        type = with types; attrsOf anything;
        default = {};
        description = ''
          Nixpkgs-compatible "meta" attributes.
        '';
      };
    };
  };
  config = {
    Tow-Boot = {
      outputs.firmware = lib.mkDefault (pkgs.callPackage (
        { stdenv
        , lib
        , buildPackages
        , src
        , defconfig
        , patches
        , variant
        , uBootVersion
        , outputName
        , buildUBoot
        , boardIdentifier
        , towBootIdentifier
        , additionalArguments
        , installPhase
        , makeFlags
        , buildInputs
        , nativeBuildInputs
        , postPatch
        }:

        stdenv.mkDerivation ({
          pname = "${config.Tow-Boot.outputName}-${defconfig}-${variant}";
          inherit variant;
          inherit boardIdentifier;

          version = "${uBootVersion}-${towBootIdentifier}";

          inherit src;

          inherit patches;

          outputs = [
            "out"
          ];

          postPatch = ''
            patchShebangs scripts
            patchShebangs tools
            patchShebangs arch/arm/mach-rockchip
          '' +
            # FIXME: review how we patch this out... (I don't like it)
          ''
            echo ':: Patching baud rate'
            (PS4=" $ "
            for f in configs/*rk3399* configs/*rk3328*; do
              (set -x
              sed -i"" -e 's/CONFIG_BAUDRATE=1500000/CONFIG_BAUDRATE=115200/' "$f"
              )
            done
            for f in arch/arm/dts/*rk3399*.dts* arch/arm/dts/*rk3328*.dts*; do
              (set -x
              sed -i"" -e 's/serial2:1500000n8/serial2:115200n8/' "$f"
              )
            done
            )
          ''
          + (lib.optionalString (!buildUBoot) ''
            substituteInPlace include/tow-boot_env.h \
              --replace "@boardIdentifier@" "${boardIdentifier}"
          '')
          + postPatch
          ;

          buildInputs = buildInputs;

          nativeBuildInputs = [
            buildPackages.bc
            buildPackages.bison
            buildPackages.dtc
            buildPackages.flex
            buildPackages.openssl
            buildPackages.swig
            buildPackages.gnutls  # For tools/mkeficapsule
            buildPackages.libuuid # For tools/mkeficapsule
            (buildPackages.python3.withPackages (p: [
              p.libfdt
              p.setuptools # for pkg_resources
            ]))
          ] ++ nativeBuildInputs;

          depsBuildBuild = [ buildPackages.stdenv.cc ];

          hardeningDisable = [ "all" ];

          makeFlags = [
            "DTC=dtc"
            "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
          ] ++ makeFlags;

          # Inject defines for things lacking actual configuration options.
          NIX_CFLAGS_COMPILE = optionals withLogo [
            "-DCONFIG_SYS_VIDEO_LOGO_MAX_SIZE=${toString (1920*1080*4)}"
          ];

          extraConfig = ''
            #
            # From structured config
            #
            ${evaluatedStructuredConfig.config.configfile}
          '';

          passAsFile = [ "extraConfig" ];

          configurePhase = ''
            runHook preConfigure
            make ${defconfig}
            cat $extraConfigPath >> .config
            make $makeFlags "''${makeFlagsArray[@]}" oldconfig

            runHook postConfigure

            (
            echo
            echo ":: Validating required and suggested config options"
            echo
            ${evaluatedStructuredConfig.config.validatorSnippet}
            )
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out
            mkdir -p $out/config
            cp .config $out/config/$variant.config
            mkdir -p $out/binaries
            ${installPhase}
            runHook postInstall
          '';

          enableParallelBuilding = true;

          dontStrip = true;
        } // additionalArguments)
      ) {
        inherit (config.Tow-Boot)
          src
          defconfig
          patches
          variant
          uBootVersion
          outputName
          buildUBoot
        ;
        inherit (config.Tow-Boot.builder)
          additionalArguments
          installPhase
          makeFlags
          buildInputs
          nativeBuildInputs
          postPatch
        ;
        boardIdentifier = config.device.identifier;
        inherit towBootIdentifier;
      });

      builder = {
        postPatch = mkIf ((!config.Tow-Boot.buildUBoot) && config.Tow-Boot.setup_leds != null) ''
          substituteInPlace include/tow-boot_env.h \
            --replace 'setup_leds=echo\0' 'setup_leds=${config.Tow-Boot.setup_leds}\0'
        '';
        makeFlags = mkMerge [
          (mkIf withLogo [
            # Even though the build will actively use the compressed bmp.gz file,
            # we have to provide the uncompressed file and file name here.
            (let
              # To produce the bitmap image:
              #     convert input.png -depth 8 -colors 256 -compress none output.bmp
              # This tiny build produces the `.gz` file that will actually be used.
              compressedLogo = pkgs.buildPackages.runCommandNoCC "uboot-logo" {} ''
                mkdir -p $out
                cp ${../../assets/splash.bmp} $out/logo.bmp
                (cd $out; gzip -n -9 -k logo.bmp)
              '';
            in "LOGO_BMP=${compressedLogo}/logo.bmp")
          ])
        ];
        meta = {
          platforms = [config.system.system];
        };
      };
    };
  };
}
