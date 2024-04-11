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
  * "Prunes" the raw built app, doing one-time removal of build-time-only dependencies, etc.
  * "Stashes" the raw built app at `/Applications/Octave-<blah>-BUILT.app`.
* Copy that raw app to `./build` for munging. (`$APP_BUILD`, and `$APP_BUILD_USR` under it)
* Munge it: do transforms that aren't just the brew installs, to turn this in to a functional Mac app.
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

### "Staged" or "built" app

Once the raw app is built, I want to preserve it, but get it out of the way so there's room to drop the final app in place from the installer. But also occasionally bring it back for examination. For example, the `brew` command inside the Octave.app build will (probably) only work if it's in its original location. This shuffling around I'm calling "staging" and "unstaging.

I'm calling these locations and actions:

* "Staged" – the final `/Applications/Octave-<blah>.app` location.
  * When a built raw app (not the post-munging app) is there, it is "staged".
* "Unstaged" aka "built" – the `/Applications/Octave-<blah>-BUILT.app` location, where the raw app is held off to the side.

The concepts and terminology are a little messy here: before 2023, I used and `-UNSTAGED` suffix instead of `-BUILT`, and had both of those coexist for a while. And the `-UNSTAGED` one was manually-ish managed. But as of 2024-01-18, I think they serve exactly the same purpose, so now I'm just using `-BUILT` as the suffix, and calling that "unstaged". Changed the bundler script to work that way, with the `stage_*` action moving it between `-BUILT` and the main location.

In some of the code, I've also called this "unstaged" `-BUILT` location the "stash" location. Should unify that terminology.

There's a `STAGING` file directly under `Octave-<blah>.app` used to indicate whether this is a staged build (in the process of being built and managed locally) as opposed to a finall app installed from the installer.

TODO: I think the "re-stage from existing `-BUILT`" and "create a new `.app` from scratch" actions need to be distinguished here. Probably only use the term "stage" for re-staging an existing app. And *then* I think we need an option to stage the post-munged build from `./build` for the signing step. I tried to keep things "simple" by unifying these actions, but I think that just doesn't quite work. And then I probably need to distinguish the "complete an unfinished build" action from "start a new build from scratch.

## Dependencies and Quirks

We have a dependency on svn for one reason only, to download netpbm, which does not do normal releases with tarballs or other distribution archives. This is a bummer because subversion is big: it depends on ruby, which depends on rust. That's like a GB of installs and a long time building. Dep chain: octave -> fig2dev -> netpbm. My `fig2dev-octapp` and `netpbm-octapp` formulae are an attempt to avoid the subversion dependency, but I haven't been able to get them working reliably yet as of 2023.

As of 2024-01, the `brew install subversion` is unconditional. Would be nice to have it be conditional on whether the formuale we're using for the build actually require svn. Nontrivial: would require chasing a couple levels of dependencies. Maybe there's a `brew depends` or `brew depends-tree` command that can walk the dependency tree for us and we can just grep for netpbm vs. netpbm-octapp? As of 2024-01-18, working on an experimental version of this, using `brew deps --include-build octave-octapp@8.4.0 | grep netpbm | grep -v netpbm-octapp`. So far, I think it can detect this case, but I don't have a current working netpbm-octave formula that can be used to give me the no-svn-needed case.

### Tool version dependencies

As of 2024-03, some of the package builds are broken under Xcode 15.3, so you need to use older versions like Xcode 15.2 and Xcode CLT 15.1. See this [#266 "Qt 5.15 builds fail... with Xcode 15.3" bug](https://github.com/octave-app/octave-app/issues/266).
