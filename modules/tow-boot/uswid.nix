{ config, lib, pkgs, ... }:

let
  inherit (lib)
    concatStringsSep
    mkOption
    optional
    types
  ;

  inherit (config.Tow-Boot)
    outputName
    towBootIdentifier
    uBootVersion
    variant
  ;

  inherit (config)
    device
  ;

  #
  # For the definition of the fields, refer to:
  #
  #  - ISO/IEC 19770-2:2015 (Preferred)
  #      - https://standards.iso.org/iso/19770/-2/2015/schema.xsd
  #      - https://web.archive.org/web/20230824211322/https://standards.iso.org/iso/19770/-2/2015/schema.xsd
  #
  #  - RFC9393 (Adequate)
  #      - https://datatracker.ietf.org/doc/html/rfc9393
  #
  #  - NIST.IR 8060 (Okay, too)
  #      - https://nvlpubs.nist.gov/nistpubs/ir/2016/NIST.IR.8060.pdf
  #
  uSWIDData = {
    "uSWID" = {
      # Will be replaced during execution with basename of $out (guaranteed meaningfully unique)
      # DO NOT assume any useful form when consuming the SWID.
      tag-id = "$id";

      # (Unchanging) meaningful name for end-user
      software-name = "${outputName} for ${device.name} [variant: ${variant}]";

      # Short description for the software (shown in e.g. fwupd frontends)
      summary = "An opinionated distribution of U-Boot";

      # Lexicographically sortable version name
      # (pre/post suffixes will not sort as expected, but that is okay)
      software-version = "${"${uBootVersion}-${towBootIdentifier}"}";
      version-scheme = "multipartnumeric+suffix";

      # Tow-Boot or U-Boot, depending on how the tooling is used.
      product = outputName;

      # An identifier (GUID suggested) that refers to a "set of software components that are related",
      # "but may be different versions".
      #
      # We're using the device identifier and variant here, since the only "related"
      # components would be the same board, same variant components here.
      # Changing from one variant to another is a "major" change all things considered.
      #
      # When tracking updates, assuming the same `persistent-id` works on the same system is okay.
      persistent-id = "org.Tow-Boot.${outputName}.${device.identifier}.${variant}";
    };
    # The entity producing this tag...
    "uSWID-Entity:TagCreator" = {
      name = "Tow-Boot";
      regid = "tow-boot.org";
      # ... And its role(s) with regard to the software.
      # "pre-defined roles include: aggregator, distributor, licensor, softwareCreator, tagCreator"
      extra-roles = concatStringsSep "," (
        [
          # Distributor assumed to mean "provides binaries"
          "Distributor"
          "Licensor"
          "Maintainer"
        ]
        # Creator of the "distribution"
        ++ (optional (outputName == "Tow-Boot") "SoftwareCreator")
      );
    };
  };
in
{
  options = {
    Tow-Boot.uswid = {
      output = {
        helper = mkOption {
          type = types.package;
          internal = true;
          description = ''
            Helper script filling most details for the uSWID.

            Only missing input is the `tag-id`, passed as the first argument.
          '';
        };
      };
    };
  };
  config = {
    Tow-Boot.uswid.output.helper = pkgs.buildPackages.callPackage (
      { lib
      , writeShellScript
      , Tow-Boot
      , uSWIDData
      }:
      writeShellScript "generate-uswid" ''
        set -e
        set -u
        PS4=" $ "

        id="$1"
        shift

        cat > uswid.tmp.ini <<EOF
        ${lib.generators.toINI {} uSWIDData}
        EOF
        (
        set -x
        ${Tow-Boot.uswid}/bin/uswid --load uswid.tmp.ini "$@"
        )
        rm uswid.tmp.ini
      ''
    ) {
      inherit uSWIDData;
    };
  };
}
