# TODO - octave-app-bundler

## Bugs

Nothing big, currently!

## Big stuff

* A "tracer-bullet" build-debugging option
  * That builds a simple HelloWorld app instead of a real Octave, so you can test the packaging tools all the way through without having to do a three-hour real build.

## Miscellaneous

* Use 2-part "x.y" version label for ".0"-patch releases, for friendliness, and consistency with how most Octave devs and users seem to use it.
* pkg customization: include the _betaN, _uN, etc. suffixes in the version directory for package installation.
  * Because DLL linkage and file references will have that baked in, plus DLL versions may differ between pre/update releases, so packages with native extensions can't really be shared.
* Option that will eagerly prompt for all permissions approvals (like Finder prettification and Terminal file access) needed throughout the process.
* Clarify what "staged" and "unstaged" mean for builds.
  * I think we're using them inconsistently and vaguely at this point.
  * Problem: I need to run `octave` from the pre-munged built app to grab version info. Maybe I could push that up to the build step instead of the munge step?
* Remove the `/usr/bin/` prefix for commands, and just say the user shouldn't shadow them incompatibly? Would make the code more readable IMHO.
* A `clean` action that removes `build/`, handling the "permission denied" errors you get on app bundle with `rm`.
* Record each build, with package versions, in the octave-app repo or somewhere, as part of release process; tool to support this, including diffing versions between those records. Include build timings.
* Identify each build or build run with a UUID? Because versions aren't sufficient.

## Disk image stuff

* Read: <http://preserve.mactech.com/articles/mactech/Vol.20/20.01/DistributingYourSoftware/index.html>

## Refactoring and code style

* Better names for path variables
  * The INSTALL_DIR, INSTALL_BUILT, INSTALL_DIR_UNSTAGED var names; dunno about those.
  * Maybe APP_INSTALL, APP_BUILD, and then `_USR` suffixes on them?
* Use shellcheck on this thing.
* Replace some globals with function arguments, for their use inside functions at least?
