Making a release
================

Prep work
---------

### Check for "foundational" software upgrades

Mainly *Trusted Firmware-A*. If a new release was made, upgrade it.


At release time
---------------

We have **one** commit with the released name/version un-suffixed.

Use the `support/release.sh` script to update the version numbers, make the
commits and tag accordingly.


After the release
-----------------

### Update Nixpkgs

Not strictly needed, but upgrading Nixpkgs frequently enough helps us stay on
top of updates for dependencies.

Updating the pinned Nixpkgs after the release ensures we're testing the change
for the longest time possible.
