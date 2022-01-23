{ config, lib, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
in
{
  options = {
    Tow-Boot = {
      config = mkOption {
        type = with types; listOf (functionTo attrs);
        description = ''
          Functions returning structured config.

          The functions take one argument, an attrset of helpers.
          These helpers are expected to be used with `with`, they
          provide the `yes`, `no`, `whenOlder` and similar helpers
          from `lib.kernel`.

          The `whenHelpers` are configured with the appropriate
          version already.
        '';
      };
      structuredConfigHelper = mkOption {
        internal = true;
        type = types.unspecified;
        description = ''
          Partially applied helper to use the KConfig-compatible structured config.
        '';
      };
    };
  };

  config = {
    Tow-Boot = {
      structuredConfigHelper =
        version:
        let
          helpers = lib.kernel // (lib.kernel.whenHelpers version);
        in
          lib.mkMerge
            (map (fn: fn helpers) config.Tow-Boot.config)
        ;
    };
  };
}
