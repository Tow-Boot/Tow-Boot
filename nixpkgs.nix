let
  rev = "f292b4964cb71f9dfbbd30dc9f511d6165cd109b";
  sha256 = "sha256:01yzrkrb60dd2y2y3fh4939z374hf5pa92q8axfcygqlnbk3jpb4";
  tarball = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
    inherit sha256;
  };
in
builtins.trace "Using default Nixpkgs revision '${rev}'..." (import tarball)
