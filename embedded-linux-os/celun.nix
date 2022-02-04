let
  rev = "41bd4c1f870ce73d59bb1348de6cabac7a145da3";
  sha256 = "0r6nkkn0iy26j3i8rqmwkdlgng5y40zgqfk7kwswvw856d5px043";
in
builtins.fetchTarball {
  url = "https://github.com/celun/celun/archive/${rev}.tar.gz";
  inherit sha256;
}
