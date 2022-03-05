{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
  inherit (config.Tow-Boot.installer.outputs)
    installerProgram
  ;
in
{
  options = {
    Tow-Boot = {
      installer = {
        config = {
          deviceName = mkOption {
            description = "User-friendly name for the device.";
            type = types.str;
          };
          targetBlockDevice = mkOption {
            description = "Block device to install to";
            type = types.str;
          };
          storageMedia = mkOption {
            description = "Storage media type";
            type = types.enum [ "SPI" "EMMC" "EMMCBOOT" ];
          };
          payload = mkOption {
            description = "File to install to the storage media";
            type = types.path;
          };
        };
        outputs = {
          installerProgram = mkOption {
            internal = true;
            type = types.package;
          };
        };
      };
    };
  };

  config = {
    Tow-Boot.installer.outputs.installerProgram = pkgs.callPackage (
      { stdenv
      , fetchFromGitHub

      , pkg-config

      , freetype
      , libdrm
      , libinput
      , libxkbcommon

      # Configuration
      , deviceName
      , targetBlockDevice
      , storageMedia
      , payload
      }:
      stdenv.mkDerivation {
        name = "tow-boot-installer-gui";
        src = fetchFromGitHub {
          owner = "Tow-Boot";
          repo = "touch-installer";
          rev = "1e506f7800f750efe75df53cc0176c4afaa1d033";
          sha256 = "sha256-KAJyy8urh7vKwq+1/icaYLZU633nwsLeEE6NG8fV+zk=";
        };
        lvgui = fetchFromGitHub {
          owner = "mobile-nixos";
          repo = "lvgui";
          rev = "3860789bb3bafc3013f11a21fe4660ad67a0d0ff";
          sha256 = "sha256-nTlq1iexQZ/2O/N3TdN36cWbBJB0y/w0mt+K9y0tS0s=";
        };

        nativeBuildInputs = [
          pkg-config
        ];

        buildInputs = [
          freetype
          libdrm
          libinput
          libxkbcommon
        ];

        postPatch = ''
          cp -r "$lvgui" lvgui
          chmod -R +w lvgui
        '';

        CFLAGS = [
          ''-DTBGUI_ASSETS_PATH='"/etc/tow-boot-installer-gui/"' ''
          ''-DDEVICE_NAME='"${deviceName}"' ''
          ''-DTARGET_BLOCK_DEVICE='"${targetBlockDevice}"' ''
          ''-DTOW_BOOT_SOURCE_FILE='"${payload}"' ''
          ''-DTBGUI_INSTALL_TO_${storageMedia}''
        ];

        makeFlags = [
          "LVGL_ENV_SIMULATOR=0"
        ];

        installFlags = [
          "PREFIX=$(out)"
        ];
      }
    ) {
      inherit (config.Tow-Boot.installer.config)
        deviceName
        targetBlockDevice
        storageMedia
      ;
      payload = "/payload.bin";
    };

    wip.stage-1.contents = {
      "/payload.bin" = pkgs.runCommandNoCC "payload.bin" { } ''
        mkdir -p $out/
        cp ${config.Tow-Boot.installer.config.payload} $out/payload.bin
      '';

      "/etc/tow-boot-installer-gui" = pkgs.runCommandNoCC "tow-boot-installer-assets" {} ''
        mkdir -p $out/etc/tow-boot-installer-gui
        cp -rvt $out/etc/tow-boot-installer-gui \
          ${installerProgram.src}/installer.svg \
          ${installerProgram.src}/fonts
      '';
    };

    examples.touch-installer.extraUtils.packages = [
      {
        package = installerProgram;
      }
    ];
  };
}
