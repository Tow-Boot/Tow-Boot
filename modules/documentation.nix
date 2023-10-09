{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    optionalString
    types
  ;
  inherit (config.device)
    identifier
  ;

  withMMCBoot = config.hardware.mmcBootIndex != null;
  withSPI = config.hardware.SPISize != null;
  withDedicatedStorage = withSPI || withMMCBoot;

  inherit (config) device;
  fullName = "${device.manufacturer} ${device.name}";
in
{
  options = {
    documentation = {
      helpers = {
        genericInstallationInstructionsTemplate = mkOption {
          type = types.unspecified;
          internal = true;
          description = ''
            Function that returns a markdown snippet with generic installation
            instructions.
          '';
        };
        genericSharedStorageInstructionsTemplate = mkOption {
          type = types.unspecified;
          internal = true;
          description = ''
            Function that returns a markdown snippet with generic shared
            storage strategy instructions.
          '';
        };
      };
      sections = {
        installationInstructions = mkOption {
          type = types.str;
          internal = true;
          description = ''
            Markdown fragment with device installation instructions.
          '';
        };
      };
      supportLevelDescriptions = mkOption {
        type = with types; attrsOf attrs;
        internal = true;
        readOnly = true;
        default = {
          "supported" = {
            title = "Supported";
            description = ''
              These devices are supported, and regularly verified to work.
            '';
            order = 0;
          };
          "best-effort" = {
            title = "Best effort";
            description = ''
              These devices are almost supported, but lack regular hardware validation by contributors and maintainers.

              They are likely to work just fine.
            '';
            order = 1;
          };
          "experimental" = {
            title = "Experimental";
            order = 5;
            description = ''
              These devices are included in the release builds, and may be verified.

              They may still not work as well as better supported devices, though it is intended to support them as best as possible.
            '';
          };
          "unsupported" = {
            title = "Unsupported";
            description = ''
              These devices are not abandoned, but not supported.

              Lower your expectations.
            '';
            order = 10;
          };
          "abandoned" = {
            title = "Abandoned";
            description = ''
              These devices are still in the repository, but are unmaintained, and abandoned.

              Expect them to be removed.
            '';
            order = 11;
          };
        };
      };
    };
  };

  config = {
    documentation.helpers.genericSharedStorageInstructionsTemplate =
      { storage ? "an SD card or eMMC" }:
      ''

        ### Installing to shared storage

        Using the shared storage strategy on the *${fullName}* can be done by
        writing the `shared.disk-image.img` to ${storage}.

        ```
         # dd if=shared.disk-image.img of=/dev/XXX bs=1M oflag=direct,sync status=progress
        ```

      ''
    ;
    documentation.helpers.genericInstallationInstructionsTemplate =
      { storage ? "an SD card"
      , startupConflictNote
      }:
      ''
        ## Installation instructions

        ${optionalString withSPI ''

          ### Installing to SPI (recommended)

          ${startupConflictNote}

          By installing Tow-Boot to SPI, your *${fullName}* will be able to
          start using standards-based booting without conflicting with the
          operating system storage.
          
          To do so, you will need to write the SPI installer image to ${storage}.

          ```
           # dd if=spi.installer.img of=/dev/XXX bs=1M oflag=direct,sync status=progress
          ```

          Once done, start the system, and in the boot menu, select
          *“Flash firmware to SPI”*.

          Once this is done, remove the installation media, and verify Tow-Boot
          starts from power-on.


        ''}
        ${optionalString withMMCBoot ''

          ### Installing to eMMC Boot${optionalString (!withSPI) " (recommended)"}

          ${startupConflictNote}

          By installing Tow-Boot to eMMC Boot, your *${fullName}* will be able to
          start using standards-based booting without conflicting with the
          operating system storage.
          
          To do so, you will need to write the eMMC Boot installer image to ${storage}.

          ```
           # dd if=mmcboot.installer.img of=/dev/XXX bs=1M oflag=direct,sync status=progress
          ```

          Once done, start the system, and in the boot menu, select
          *“Flash firmware to eMMC Boot”*.

          Once this is done, remove the installation media, and verify Tow-Boot
          starts from power-on.

        ''}

        ${config.documentation.helpers.genericSharedStorageInstructionsTemplate {}}
      ''
    ;

    documentation.sections.installationInstructions =
      lib.mkOptionDefault
      (builtins.throw "${identifier} missing installationInstructions...")
    ;
  };
}
