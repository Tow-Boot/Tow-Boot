Development Guide
=================

Required setup
--------------

A Linux host and Nix are the two requirements for this project. Knowledge about
using `git` will help, but fetching a tarball or zip from GitHub could do in a
pinch.

### Nix

The author uses NixOS, but NixOS is not a requirement.

Only *Nix* the package manager is required to build this project. It can be
installed on any Linux distribution.

#### I don't want to or can't install `Nix` on my system

Sorry.

Though you can use a Docker container image **TODO** that is pre-configured to
work well with this project.

Using Nix through Docker is not ideal, but should work when working under
specific conditions.

While Nix works on macOS, this project require a Linux builder to work. Using
the Docker builder is an alternative to setting up a Linux virtual machine.
After all, Docker on macOS is a specialized Linux virtual machine. **TO BE TESTED**


A primer on Nix
---------------

First, read more about Nix elsewhere. Nix here is used as a glue to configure
the builds.

Knowing Nix will help you better understand what you are looking at.

Look at the following resources.

 - [nix-1p](https://github.com/tazjin/nix-1p) probably is the best condensed primer on Nix.

The upstream manuals of the NixOS project are good, but mainly *when you already
have knowledge about Nix*. They are more of a reference than a learning resource.

 - [Nix Manual](https://nixos.org/manual/nix/stable/)
 - [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)
 - [NixOS Manual](https://nixos.org/manual/nixos/stable/)


Important concepts
------------------

### What's `callPackage`?

`callPackage` is a sort of dependency injection that is borrowed from *Nixpkgs*.

 - Allows dependency injection
 - Makes the derivations "overridable"

The dependency injection makes it so we don't have to really care about where
the dependencies are in the codebase. As long as it's in the scope `callPackage`
is working with, we can "ask" for a dependency.

Making derivations "overridable" allows us to customize the derivations. This
can be used for dependencies coming from Nixpkgs, or to make one-off
customizations of our own derivations.

