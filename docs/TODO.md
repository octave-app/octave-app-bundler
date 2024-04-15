# TODO - octave-app-bundler

## Bugs

Nothing specific at the moment.

## Miscellaneous

* Add timing and metrics (CPU, mem?) output to the build script.
* Capture the output of `bundle_octave_app` itself to a log file in `build/logs`.
* Clarify what "staged" and "unstaged" mean for builds.
  * I think we're using them inconsistently and vaguely at this point.
  * Problem: I need to run `octave` from the pre-munged built app to grab version info. Maybe I could push that up to the build step instead of the munge step?
* Remove the `/usr/bin/` prefix for commands, and just say the user shouldn't shadow them incompatibly? Would make the code more readable IMHO.
* A `clean` action that removes `build/`, handing the "permission denied" errors you get on app bundle with `rm`.
* Record each build, with package versions, in the octave-app repo or somewhere, as part of release process; tool to support this, including diffing versions between those records.
* Identify each build or build run with a UUID? Because versions aren't sufficient.
* Make Qt dependency nonoptional? There's kinda no point in building a non-GUI Octave.app, and it would make the formulae cleaner, esp. in terms of diffs wrt the core formulae. Same with Java.

## Disk image stuff

* Use APFS instead of HFS+?
* Read: <http://preserve.mactech.com/articles/mactech/Vol.20/20.01/DistributingYourSoftware/index.html>

## Refactoring and code style

* Better names for path variables
  * The INSTALL_DIR, INSTALL_BUILT, INSTALL_DIR_UNSTAGED var names; dunno about those.
  * Maybe APP_INSTALL, APP_BUILD, and then `_USR` suffixes on them?
* Use shellcheck on this thing.
* Replace some globals with function arguments, for their use inside functions at least?

## More-incremental builds

* [in-progress] Leave a pristine copy of the original (pre-munging) `/Applications/Octave` app there at like "Octave-BUILT.app", to be able to reliably pick up the process at the munging stage without repeating the long build, and not tempt the operator to delete the original build when it's time to drop the completed app bundle from the DMG in its final place. Probably do this unconditionally after the build is complete and before it's time to munge, so no manual intervention is needed. In fact, use this instead of the old staged/unstaged thing, which isn't as well-defined as I'd like.
