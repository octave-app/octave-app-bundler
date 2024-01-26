# Release and Dev History Notes

This is a loose collection of history notes, just to jog my memory. For internal consumption, not user-facing like the CHANGELOG is.

## Releases

### 8.4.0 alpha4

* Add the missing netcdf dependency (used by OF packages) to the 8.x formulae.
* Tweak bundler options – `-Y` instead of `-y` for dry run, add a `--debug-no-errexit` now that errexit is the default, and remove the `--exit-on-error`.
