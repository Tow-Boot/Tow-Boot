#!/usr/bin/env bash

#
# This script is ran from outside the docker/podman environment, to run itself into
# the docker/podman environment.
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


_nix_container_manager() {

	# Ask if the user wants to proceed as root
	if (($(id -u) == 0)); 
	then
		stderr.printf ""
		stderr.printf "You don't need to run this script as root."
		stderr.printf ""
		stderr.printf "Learn more on how run docker/podman in rootless mode:"
		stderr.printf " Docker: https://docs.docker.com/engine/security/rootless/"
		stderr.printf " Podman: https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md"
		stderr.printf ""
		PS3="Running as root. Do you want to continue?: "

		select yn in "Yes" "No"; do
			case $yn in
				Yes) 
					stderr.printf "\nProceeding as root user\n"
					break
					;;
				No)
					stderr.printf "\nQuiting the build script...\n"
					exit 0
					;;
			esac
		done
	fi

	# Find which container manager is available

	declare -a availableManagers=()

	# Check if docker is available
	if ! command -v docker &> /dev/null;
	then
		stderr.printf "Docker not installed\n"
	else
		availableManagers+=('docker')
	fi


	# Check if podman is available
	if ! command -v podman &> /dev/null;
	then
		stderr.printf "Podman not installed\n"
	else
		availableManagers+=('podman')
	fi

	# Exit if neither docker or podman is available
	if [ ${#availableManagers[@]} -eq 0 ]
	then
		stderr.printf "\nCan't find docker or podman on your system.\nInstall one of them to continue...\n"
		exit 1
	fi

	# Add exit command
	availableManagers+=('Quit')
	

	local selectedManager
	# Use switch statements to select from the available managers
	stderr.printf "\nAvailable container managers on your system:\n"
	PS3="Select one of the options or quit: "
	select manager in ${availableManagers[*]}; do
		case $manager in
			docker|podman)
				stderr.printf "\nSelected:\n $manager\n"
				selectedManager=$manager
				break
				;;
			Quit)
				stderr.printf "\nSee you soon!\n"
				exit 0	
				;;
			*)
				stderr.printf "\nInvalid option\n"
				;;
		esac
	done


	# Check if the image is available
	declare checkImg
	case $selectedManager in
		docker)
			checkImg="$($selectedManager image ls -a nixos/nix | grep -Fq nixos/nix; echo $?)"
			;;
		podman)
			checkImg=$($selectedManager image exists nix; echo $?)
			;;
		*)
			stderr.printf "\nUnexpected value for selectedManager ($selectedManager) when checking image is present.\n"
			exit 1
			;;
	esac
	
	# Pull the image if it doesn't exists
	if (( $checkImg == 0 ));
	then
		stderr.printf "\nNixOS image is present\n"
	elif (( $checkImg == 1 ));
	then
		stderr.printf "\nCan\'t find NixOS image. Pulling...\n"
		$selectedManager pull docker.io/nixos/nix
	fi

	# Check if the volume exists
	local STORE_VOLUME
	declare volumeExists
	case $selectedManager in
		docker)
			volumeExists=$($selectedManager volume ls | grep -Fq Tow-Boot--nix-store; echo $?)
			;;
		podman)
			volumeExists=$($selectedManager volume exists Tow-Boot--nix-store; echo $?)
			;;
		*)
			stderr.printf "\nUnexpected value for selectedManager ($selectedManager) when checking volume exists.\n"
			exit 1
			;;
	esac

	if (( $volumeExists == 0 )); 
	then
		stderr.printf "\n(Using existing volume)\n"
		STORE_VOLUME="Tow-Boot--nix-store"
	else
		stderr.printf "\n(Volume doesn\'t exist. Creating...)\n"
		STORE_VOLUME="$($selectedManager volume create "Tow-Boot--nix-store")"
	fi

	$selectedManager run \
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
		stderr.printf "Error: the docker/podman wrapper script needs to be executed in the Tow-Boot checkout.\n"
		exit 1
	fi

	# Outside the container environment, we're calling this script in the container.
	_nix_container_manager /Tow-Boot/support/docker/build.sh \
		"$(id -u)" "$(id -g)" \
		"$@"
fi
