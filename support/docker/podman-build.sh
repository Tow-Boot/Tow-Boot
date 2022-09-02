#!/usr/bin/env bash

#
# This script is ran from outside the podman environment, to run itself into
# the podman environment.
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

_nix_podman() {
	checkImg=$(podman image exists; echo $?)
	if (($checkImg == 0));
	then
		stderr.printf "\nNixOS image is present\n"
	else
		stderr.printf "\nCan\'t find NixOS image. Pulling...\n"
		podman pull docker.io/nixos/nix
	fi

	local STORE_VOLUME
	volumeExists=$(podman volume exists Tow-Boot--nix-store; echo $? )
	#echo $result 
	if (( $volumeExists == 0 )); 
	then
		stderr.printf "\n(Using existing volume)\n"
		STORE_VOLUME="Tow-Boot--nix-store"
	else
		stderr.printf "\n(Volume doesn\'t exist. Creating...)\n"
		STORE_VOLUME="$(podman volume create "Tow-Boot--nix-store")"
	fi

	podman run \
		--volume "$STORE_VOLUME:/nix" \
		--volume "$project_dir:/Tow-Boot" \
		--workdir "/Tow-Boot/$relative_dir" \
		-it nixos/nix \
		"$@"
}

if [ -e /Tow-Boot ]; then
	REAL_UID="$1"; shift
	REAL_GID="$1"; shift

	# It's fine to use a static name here since it's an ephemeral container.
	mkdir -p "/tmp-build-dir"
	cd "/tmp-build-dir"

	# Call `nix-build`, showing the user the actual invocation.
	(
	NIX_PATH="Tow-Boot=/Tow-Boot"
	set -x
	nix-build \
		--cores 0 \
		'<Tow-Boot/default.nix>' \
		"$@"
	)

	stderr.printf "\n(Unwrapping store paths...)\n"

	for f in *; do
		target="$(readlink -f "$f")"
		rm -rf "$current_dir/$f"
		stderr.printf "%s -> %s\n" "$f" "$target"
		cp -r "$target" "$current_dir/$f"
		chown -R "$REAL_UID:$REAL_GID" "$current_dir/$f"
	done
else
	if [[ "$relative_dir" =~ ^/ ]]; then
		stderr.printf "Error: the podman wrapper script needs to be executed in the Tow-Boot checkout.\n"
		exit 1
	fi

	# Outside the podman environment, we're calling this script in the container.
	_nix_podman /Tow-Boot/support/docker/podman-build.sh \
		"$(id -u)" "$(id -g)" \
		"$@"
fi
