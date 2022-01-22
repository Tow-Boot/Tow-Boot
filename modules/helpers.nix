{ config, lib, ... }:

{
  options.helpers = {
    verbosely = lib.mkOption {
      type = lib.types.unspecified;
      internal = true;
      default = msg: val: if config.verbose then msg val else val;
      description = ''
        Function to use to *maybe* builtins.trace things out.

        Usage:

        ```
        { config, /* ..., */ ... }:
        let
          inherit (config) verbosely;
        in
          /* ... */
        ```
      '';
    };
  };
}
