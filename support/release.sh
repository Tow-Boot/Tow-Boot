#!/usr/bin/env bash

#
# Due to inclusion of a CC-BY-SA 3.0 snippet, this whole script is CC-BY-SA
#
# https://creativecommons.org/licenses/by-sa/3.0/
#
# This applies to the script content only.
#

set -e
set -u
PS4=" $ "
set -x

# Remove the `-pre` suffix
sed -i -e \
	's/additionalIdentifier = "-pre";/additionalIdentifier = "";/' \
	support/builders/tow-boot/default.nix

# Commit and tag the version
version="$(nix-instantiate --eval -E '(import ./release.nix {}).version' | sed -e 's/"//g')"
git add support/builders/tow-boot/default.nix
git commit -m "release $version"
git tag "release-$version"

# Increment the Tow-Boot version identifier
# (https://stackoverflow.com/a/32841608)
sed -i -e \
	's/towBootIdentifier = "[0-9]*[0-9]/&¤/g;:a {s/0¤/1/g;s/1¤/2/g;s/2¤/3/g;s/3¤/4/g;s/4¤/5/g;s/5¤/6/g;s/6¤/7/g;s/7¤/8/g;s/8¤/9/g;s/9¤/¤0/g;t a};s/¤/1/g' \
	support/builders/tow-boot/default.nix

# Put back the `-pre` suffix
sed -i -e \
	's/additionalIdentifier = "";/additionalIdentifier = "-pre";/' \
	support/builders/tow-boot/default.nix

# Commit post-release bump
git add support/builders/tow-boot/default.nix
git commit -m "post-release: Bump release number"
