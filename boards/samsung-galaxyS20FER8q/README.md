# Samsung Galaxy S20 FE (R8Q)

## Device-specific notes

This experimental target builds the R8Q U-Boot source at a pinned commit. It
is excluded from Tow-Boot release artifacts until the build and output flow
have been validated through Tow-Boot.

The output is a U-Boot build, not a Tow-Boot-branded firmware port: the source
repository does not include Tow-Boot's patches. Generic Tow-Boot disk and
installer images are intentionally not produced because Samsung requires its
own Android boot-image packaging.

The manual **Build R8Q boot image** workflow packages the result into an
Android boot image using the pinned fork's Samsung inputs. This retains the
fork's phone boot menu and boot flow, not Tow-Boot's phone UX.
