# This is a shim that calls `evalWithConfiguration` automatically, with
# some additional helpers.
# This is meant for use internally by this project.
# The interface here should not be assumed to be *stable*.
{
  pkgs ? import ../../nixpkgs.nix { }
  # The identifier of the device this should be built for.
  # (This gets massaged later on)
, device ? null
, verbose ? false
, configuration
  # Internally used to tack on configuration by release.nix
, additionalConfiguration ? {}
, additionalHelpInstructions ? ""
}:
let
  inherit (pkgs.lib) filter optionalString showWarnings strings;
  inherit (strings) concatStringsSep stringAsChars;

  inherit (import ./release-tools.nix { inherit pkgs; }) evalWith;

  # The "default" eval.
  eval' = evalWith {
    inherit additionalConfiguration device;
    modules = [{
      imports = [
        configuration
        (
          { lib, ... }:
          {
            verbose = lib.mkDefault verbose;
          }
        )
      ];
    }];
  };

  # Makes a mostly useless header.
  # This is mainly useful for batch evals.
  header = str:
    let
      str' = "* ${str} *";
      line = stringAsChars (x: "*") str';
    in
    builtins.trace (concatStringsSep "\ntrace: " [line str' line])
  ;

  # We're purposefully not using the global `verbosely` helper, as otherwise
  # it would force the modules system eval to happen before the device banner.
  verbosely = msg: val: if verbose then msg val else val;

  # Handle assertions and warnings                                                  
  failedAssertions = map (x: x.message) (filter (x: !x.assertion) eval'.config.assertions);

  # This `eval` wraps assertion checks
  eval = if failedAssertions != []
    then throw "\nFailed assertions:\n${concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
    else showWarnings eval'.config.warnings eval';
in
(
  # Break gracefully if `device` is not set.
  # TODO: better document how to provide a device
  if device == null then throw ''
    Please provide a device to build for.
    =====================================

    Add either of the following parameters:

      --argstr device vendorName-deviceName

    or

      --arg device ./boards/vendorName-deviceName

    The former is equivalent to the latter.
    The format with a path allows using a device declared out of tree.

  '' else

  # Maybe print a banner for the device eval.
  verbosely (
    if device ? special
    then header "Evaluating: ${device.name}"
    else if (builtins.tryEval (builtins.isPath device && builtins.pathExists device)).value
    then header "Evaluating device from path: ${toString device}"
    else header "Evaluating device: ${device}"
  )
)

#
# Hijack the `default` output, and shove useful eval attributes in passthru.
# This makes the default build produce a useful result, and allows usage such as:
#
#    $ nix-build --argstr device ... -A build.archive
#
eval.config.build.default.overrideAttrs({ passthru ? {}, ... }: {
  passthru = passthru // {
    inherit eval;
    inherit (eval) config pkgs;
    inherit (eval.config) build;
  };
})
