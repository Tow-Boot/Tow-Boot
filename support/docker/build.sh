#!/usr/bin/env bash

#
# This script is ran from outside the docker environment, to run itself into
# the docker environment.
#
# It will automatically handle calling `nix-build` correctly, and unwrapping
# the `result` symlink into a real directory.
#
# A `Tow-Boot--nix-store` volume will be automatically created. It will hold
# the `/nix/store` as a local binary cache. Otherwise the toolchain must be
# downloaded again every invocation.
#
# This is not a one-to-one replacement for Nix, but should be sufficient for
# basic building locally without installing Nix globally, if Docker is deemed
# more appropriate.
#

set -e
set -u
set -o pipefail
PS4=" $ "

_nix_docker() {
	local STORE_VOLUME
	STORE_VOLUME="$(docker volume create "Tow-Boot--nix-store")"

	docker run \
		--volume "$STORE_VOLUME:/nix" \
		--volume "$(cd "$(dirname "$0")/../.."; pwd):/Tow-Boot" \
		-it nixos/nix \
		"$@"
}

if [ -e /Tow-Boot ]; then
	REAL_UID="$1"; shift
	REAL_GID="$1"; shift

	cd /Tow-Boot

	# Cleanup a leftover result (unclean and rude)
	if [ -e result ]; then
		rm -rf result
	fi

	# Call `nix-build`, showing the user the actual invocation.
	(set -x
	nix-build --cores 0 "$@"
	)

	# Unwrap the `result` symlink
	out=$(readlink -f result)
	rm result
	cp -r "$out" result
	chown -R "$REAL_UID:$REAL_GID" result
else
	# Outside the docker environment, we're calling this script in the container.
	_nix_docker /Tow-Boot/support/docker/build.sh \
		"$(id -u)" "$(id -g)" \
		"$@"
fi
