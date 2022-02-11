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

project_dir="$(cd "$(dirname "$0")/../.."; pwd)"
current_dir="$(pwd)"
relative_dir="${current_dir/$project_dir/.}"

stderr.printf() {
	printf "$@" >&2
}

_nix_docker() {
	local STORE_VOLUME
	STORE_VOLUME="$(docker volume create "Tow-Boot--nix-store")"

	docker run \
		--volume "$STORE_VOLUME:/nix" \
		--volume "$project_dir:/Tow-Boot" \
		--workdir "/Tow-Boot/$relative_dir" \
		-it nixos/nix \
		"$@"
}

if [ -e /Tow-Boot ]; then
	REAL_UID="$1"; shift
	REAL_GID="$1"; shift

	# Cleanup a leftover result (unclean and rude)
	if [ -e result ]; then
		rm -rf result
	fi

	# Call `nix-build`, showing the user the actual invocation.
	(set -x
	nix-build --cores 0 "$@"
	)

	stderr.printf "(Unwrapping store paths...)\n"

	# Unwrap the `result` symlink
	out=$(readlink -f result)
	rm result
	cp -vr "$out" result >&2
	chown -R "$REAL_UID:$REAL_GID" result
else
	if [[ "$relative_dir" =~ ^/ ]]; then
		stderr.printf "Error: the docker wrapper script needs to be executed in the Tow-Boot checkout.\n"
		exit 1
	fi

	# Outside the docker environment, we're calling this script in the container.
	_nix_docker /Tow-Boot/support/docker/build.sh \
		"$(id -u)" "$(id -g)" \
		"$@"
fi
