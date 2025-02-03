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
    inherit (pkgs) path writeShellScript;
    version = config.Tow-Boot.uBootVersion;
    structuredConfig = (config.Tow-Boot.structuredConfigHelper version);
  };
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
      outputs.firmware = lib.mkDefault (pkgs.Tow-Boot.callPackage (
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
        , uswidHelper
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

          prePatch =
            ''
              cp -prf "$PWD" "$PWD.orig"
            ''
          ;

          postPatch =
            ''
              echo ":: Dropping EXTRAVERSION from Makefile"
              # Drop that from the exposed version, always.
              # We use releases, any extra qualifier is owned by us.
              sed -i -e 's/^EXTRAVERSION =.*/EXTRAVERSION =/' Makefile
            ''
            + (lib.optionalString (!buildUBoot) ''
              echo ":: Sneaking in boardIdentifier in the Tow-Boot environment"
              substituteInPlace include/tow-boot_env.h \
                --replace "@boardIdentifier@" "${boardIdentifier}"
            '')
            + postPatch
            # We're making the build diff before patching shebangs so Nix
            # store paths don't leak into the output.
            # It's also an implementation detail.
            + ''
              (
              echo ":: Snapshotting build diff"
              set -x
              # Clear up any garbage left behind while patching
              find . -name '*.orig' -delete
              # `diff` exits 1 if there's differences...
              diff --new-file --recursive --unified "$PWD.orig/" "$PWD/" > ../build.diff || :
              )
            ''
            + ''
              (
              echo ":: Patching shebangs to Nix store paths"
              patchShebangs scripts
              patchShebangs tools
              patchShebangs arch/arm/mach-rockchip
              )
            ''
          ;

          buildInputs = buildInputs;

          nativeBuildInputs = [
            buildPackages.bc
            buildPackages.bison
            buildPackages.dtc
            buildPackages.findutils
            buildPackages.flex
            buildPackages.openssl
            buildPackages.swig
            buildPackages.gnutls  # For tools/mkeficapsule
            buildPackages.libuuid # For tools/mkeficapsule
            (buildPackages.python3.withPackages (p: [
              p.libfdt
              p.pyelftools
              p.setuptools # for pkg_resources
            ]))
          ] ++ nativeBuildInputs;

          depsBuildBuild = [ buildPackages.stdenv.cc ];

          hardeningDisable = [ "all" ];

          makeFlags = [
            "DTC=${lib.getExe buildPackages.dtc}"
            "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
          ] ++ makeFlags;

          # Inject defines for things lacking actual configuration options.
          NIX_CFLAGS_COMPILE =
            (optionals withLogo (
              lib.optional (lib.versionOlder uBootVersion "2023.01") "-DCONFIG_SYS_VIDEO_LOGO_MAX_SIZE=${config.Tow-Boot.VIDEO_LOGO_MAX_SIZE}"
            ))
          ;

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

            mkdir -vp $out
            mkdir -vp $out/config

            echo ":: Copying config files"
            make $makeFlags "''${makeFlagsArray[@]}" savedefconfig

            cp -v .config $out/config/$variant.config
            cp -v defconfig $out/config/$variant.newdefconfig
            cp -v "configs/${defconfig}" $out/config/$variant.defconfig

            echo ":: Copying build diff"

            mkdir -vp $out/diff
            cp -v "../build.diff" $out/diff/$variant.build.diff

            echo ":: Copying output binaries"
            mkdir -p $out/binaries
            ${installPhase}

            if test -e $out/binaries; then
              (
              echo ":: Adding uSWID data"
              cd $out/binaries
              for binary in "${outputName}"*.bin; do
                printf " - '%s' \n" "$binary"
                ${/*
                  Most builds should produce only one output here, but in case other outputs
                  grow, we'll pre-empt problems by appending the binary name to the tagId.

                  We're referring to tagId as ISO/IEC 19770-2:2015 implies: “a unique
                  reference for the **specific** […] binary […] If two tagIDs match […] the
                  underlying products they represent are […] exactly the same”.

                  **Always** treat this tagId as an opaque blob. The useful data it
                  contains should be found elsewhere.
                */""}
                tagId="$(echo $(basename $out)/$binary | sed -e 's/-${stdenv.cc.targetPrefix}/-/')"
                ${uswidHelper} "$tagId" --compress --save uswid.bin
                cat uswid.bin >> "$binary"
                rm uswid.bin
              done
              )
            fi
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
          towBootIdentifier
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
        uswidHelper = config.Tow-Boot.uswid.output.helper;
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
              compressedLogo = pkgs.buildPackages.runCommand "uboot-logo" {} ''
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
