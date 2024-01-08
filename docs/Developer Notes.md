# Developer Notes for octave-app-bundler

## Terminology

* "octapp" – an abbreviation for "Octave.app" or "octave-app".

## Code Style

This is mostly a Bash program.

90-character line width. Indent with spaces, not tabs.

Naming:

* `$UPPER_CASE` for global variables
* `$snake_case` for local variables
* `snake_case` for functions
* Exception: global variables that are stand-ins for commands of the same name, like `$brew`, are lower case, matching the original command name.

I like this ["Shell Script Best Practices"](Shrikant Sharat Kandula) article by Shrikant Sharat Kandula, and am somewhat following it here.

We use conservative Bash settings in these scripts, including `set -o errexit` and `set -o nounset`. To work under that, use variable expansions like `${FOO:-}` in cases where it is in fact okay for the variable to be unset, and locally do a `set +o errexit; ...; set -o errexit` when you want to switch to explicit error handling for commands that may fail.

Use an explicit `local` to make all variables local unless they are actually intended to be globals.

Miscellaneous things:

* Prefer `[[ ... ]]` to `[ ... ]` for all tests.
* In `foo=$(...)` assignments, no need for quotes around the `$(...)` part.
* Use `'...'` single quotes for strings that aren't expected to have variable interpolation. But use `"..."` double quotes for strings which might be changed to have variable interpolation later, even if there isn't any now. (Like progress messages.)
* Go ahead and use `${FOO}` instead of `$FOO` if it looks more readable, even if it's not needed syntax-wise.

Prefer `info` and `error` to plain `echo` calls for outputting progress messages to the user, and `die` instead of bare `echo`/`exit` calls for errors that should abort the program. This supports adding program-name prefixing and other decorations if we want to do so in the future.

Don't export variables unless you actually need them as environment varibles in child processes. Prefer to leave them as plain shell variables.

## Build Process

Here's how the Octave.app build process works. The `$foo` vars in the remarks are the variables used in the `bundle_octave` bash script that does this.

* Build the "raw app" in `/Applications` using Homebrew.
  * Creates an `/Applications/Octave-<blah>.app` dir. (`$INSTALL_DIR`)
  * Creates a custom-prefix Homebrew installation under that, in its `Contents/Resources/usr` dir. (`$INSTALL_USR`)
  * Uses that `brew` to install `octave-octapp` and all its dependencies there under that `Octave-<blah>.app` dir.
* Copy that raw app to `./build` for munging. (`$APP_BUILD`, and `$APP_BUILD_USR` under it)
* Munge it: do transforms that aren't just the brew installs.
  * Create app-launching AppleScript. (`Contents/.../main.scpt`)
    * (This might be what actually makes it an "app bundle"?)
  * Define custom app icons. (`Contents/Resources/applet.icns`)
  * Edit the app plist. (`Contents/Info.plist`)
  * Make fontconfig use in-app font cache dir instead of global/user one.
  * Add custom app-level octaverc, which does various things.
  * Add octapp-defined custom Octave functions (to `share/octave/site`)
  * yadda yadda...


Here, "raw app" means the program and files inside the `.app` directory, before they have been turned in to an actual Mac app bundle by addition of the app launcher script and whatever else is needed to do that. ("Raw app" is a term I made up; I dunno if there's a real word for that.)

Logs for this are captured to `./build/logs`.
