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
           # dd if=mmcboot.installer.img of=/dev/XXX bs=1M oflag=direct,sync status=progress
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
