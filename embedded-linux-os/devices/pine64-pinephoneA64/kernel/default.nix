{ stdenv, fetchFromGitHub }:

# This is not actually the build derivation...
# We're co-opting this derivation as a source of truth for the version and src.
stdenv.mkDerivation rec {
  version = "5.15.0";

  src = fetchFromGitHub {
    owner = "megous";
    repo = "linux";
    rev = "3cc817fa5bfb1f9c6c1630707cd7aa6d00f4efe3";
    sha256 = "0hwi3z7sppw9pnxjjy0skrrgjicv652k6mlzz1q3nkimbfdgm6cs";
  };

  patches = [
  ];
}
