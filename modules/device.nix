{ lib, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
in
{
  options = {
    device = {
      manufacturer = mkOption {
        description = ''
          Name of the manufacturer of the board.
        '';
        type = types.str;
      };
      name = mkOption {
        description = ''
          Name of the board.
        '';
        type = types.str;
      };
      identifier = mkOption {
        description = ''
          Identifier of the board.

          Will be used internally for validation when flashing updates.
        '';
        type = types.str;
      };
    };
  };
}
