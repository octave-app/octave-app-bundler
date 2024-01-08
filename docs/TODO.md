# TODO - octave-app-bundler

## Bugs

Nothing specific at the moment.

## Miscellaneous

* Unindent the options subsections in the help screen.
* Clarify what "staged" and "unstaged" mean for builds. I think we're using them inconsistently and vaguely at this point.
  * Problems:
    * I need to run `octave` from the pre-munged built app to grab version info. Maybe I could push that up to the build step instead of the munge step?
* Check that our custom `ver.m` is in line with the new 6.x and 8.x versions of it.
* Add architecture suffix/label to DMG (but not app name or bundle) of Intel builds.
* Remove the `/usr/bin/` prefix for commands, and just say the user shouldn't shadow them incompatibly? Would make the code more readaable.
* Capture _all_ brew build logs to `build/logs`` dir, not just for the octave formula.
* Move the errexit=n option to a `--debug-no-errexit` option, since it's special use for developers.
* Remove "..." ellipses from before-action progress messages?
* Make Qt dependency nonoptional? There's kinda no point in building a non-GUI Octave.app, and it would make the formulae cleaner, esp. in terms of diffs wrt the core formulae.
* Replace `-y` short opt for `--dry-run` with `-Y` or something, because `-y` is commonly used for "yes", not "dry run".

## Refactoring and code style

* Better names for path variables
  * The INSTALL_DIR, INSTALL_BUILT, INSTALL_DIR_UNSTAGED var names; dunno about those.
  * Maybe APP_INSTALL, APP_BUILD, and then `_USR` suffixes on them?
* Rearrange script to have function definitions first, and then all the top-level code (including global variable initialization) down together at the bottom.
  * And put most of the main code in a `main()` function.
* Store build dir in a variable instead of relying on any cwd-relative paths.
* Use shellcheck on this thing.
* Replace some globals with function arguments, for their use inside functions at least?

## More-incremental builds

* Leave a pristine copy of the original (pre-munging) `/Applications/Octave` app there at like "Octave-BUILD", to be able to reliably pick up the process at the munging stage without repeating the long build, and not tempt the operator to delete the original build when it's time to drop the completed app bundle from the DMG in its final place. Probly do this unconditionally after the build is complete and before it's time to munge, so no manual intervention is needed.
