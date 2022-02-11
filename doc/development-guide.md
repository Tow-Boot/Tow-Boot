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

It is preferred to install from the official Nix installer. Using the
distribution-packaged Nix may not work.

#### I don't want to or can't install `Nix` on my system

Sorry.

Though you can use a build shim that uses a Docker container.

Using Nix through Docker is not ideal, but should work when working under
specific conditions.

When using the build shim, replace `nix-build` invocations with the path to 
the shim (e.g.`./support/docker/build.sh`). Note that this only works if the
command does not reference a nix file directly.

#### I'm not on a Linux system

While Nix works on macOS, this project require a Linux builder to work.
Using the Docker build shim may work, testing is needed, contributions welcome.


I just want to build
--------------------

You still should read a bit more past this section, but if you absolutely only
want to build, here's how you can build the `uBoot-sandbox` board.

```
 $ nix-build -A uBoot-sandbox
```

After the build is finished successfully, a `result` symlink will refer to the
build output. The build output by default is the content of the archive.

* * *

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

