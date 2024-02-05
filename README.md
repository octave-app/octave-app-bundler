# README – octave-app-bundler

This repository contains the necessary files to build Octave.app (version >=4) using Homebrew.

If you're a user and just want to run Octave.app, you don't need this repo. Instead, go to [the Octave.app Downloads page](https://octave-app.org/Download.html) to download the installer, or see [the Octave.app website](https://octave-app.org) for information. This octave-app-bundler repo just contains the tools that are used to build that installer, and is for the Octave.app developers.

More general information about installing Octave is available at <https://wiki.octave.org/Octave_for_macOS>.

## Contact

This project is maintained by the [Octave.app team](https://octave-app.org), which is on GitHub as the [octave-app organization](https://github.com/octave-app).
[Sebastian Schoeps](https://github.com/schoeps) developed the original code. [Andrew Janke](https://github.com/apjanke) is the primary maintainer as of 2020.

The home repo for this project is the [`octave-app/octave-app-bundler` GitHub repo](https://github.com/octave-app/octave-app-bundler). But that repo doesn't have its own bug tracker; octave-app-bundler is just considered part of the overall Octave.app project, and bugs for it should be reported on the [Issue Tracker for the main octave-app project](https://github.com/octave-app/octave-app/issues).

Homebrew formulae used for Octave.app are in the [`octave-app/octave-app` custom Tap](https://github.com/octave-app/homebrew-octave-app).

## Usage

Again, if you just want to *use* Octave.app instead of hack on it and its build toolchain, you should [download the pre-built installer](https://octave-app.org/Download.html) instead of running octave-app-bundler yourself.

For those who do want to build their own Octave.app from source:

Clone the [octave-app-bundler repo](https://github.com/octave-app/octave-app-bundler) with `git clone https://github.com/octave-app/octave-app-bundler`, `cd` to it, and run `./bundle_octave_app`. The defaults will build an app and installer using a recent version of Octave and all the default options. Then, you need to actually install the built app from the installer DMG or the `build/` subdirectory, and clean up the `Octave-<version>-BUILT.app` thing it left in your `/Applications` folder.

(This project is named "octave-app-bundler", but the command is named `bundle_octave_app`. There is no `octave-app-bundler` command.)

`bundle_octave_app` does have options, but they're mainly for use in creating prereleaes and updates releases, or debugging `bundle_octave_app` itself. You may want to avoid them unless you have a specific reason to use one. For details on the options, see `./bundle_octave_app --help`, and is source code.

There's also a `wip_bundle_octave_app` script or two. That's a wrapper that runs `bundle_octave_app` with the options for the release that the Octave.app team is currently working on. (Or is left over from their last release.) You can run it.

## Requirements and Dependencies

* macOS of a recent version
* TeX, from MacTeX or another TeX distribution
* GNU sed (gsed)
* Python 3, with a `python3` command.
* [create-dmg](https://github.com/create-dmg/create-dmg)

Only the most recent few versions of macOS are supported, because Octave.app is built using Homebrew, and Homebrew only supports the last three versions of macOS. The bundler script may run on older versions, and the build there may or may not work, but who knows, and it is not supported.

GNU sed is not shipped with macOS. You'll need to install it with Homebrew, MacPorts, or something else. `brew install gnu-sed` will do it.

You'll need a full TeX distribution installed. We use and recommend [MacTeX](https://www.tug.org/mactex/), the official (I think?) macOS distribution of [TeX Live](https://www.tug.org/texlive/).

Recent versions of macOS (like macOS 12 and later) include Python 3. On earlier versions, you'll need to install it with Homebrew or something else. It must provide a version-qualified `python3` command, not just plain `python`, and must be on your `$PATH`.

You need a [`create-dmg`](https://github.com/create-dmg/create-dmg) repo or installation. This tool looks for create-dmg under your `~/repos`. If you installed it somewhere else, point to it by setting the `$OCTAPP_CREATEDMG_HOME` environment variable.

## How it works

octave-app-bundler uses Homebrew to build and install Octave and all its dependencies. This is done in a separate Homebrew prefix under the target application so it (hopefully) doesn't interfere with any existing Homebrew installations. It then bundles those programs as a macOS app bundle, and creates an installer DMG using [andreyvit's `create-dmg` tool](https://github.com/create-dmg/create-dmg).

## Miscellaneous

The word "bundler" as used in this project has nothing to do with Ruby's [Bundler](https://bundler.io/) tool for managing Ruby gems. We just use that word because this tool makes a macOS "app bundle". It's just a collision of terminology; no Ruby is involved here, and the packaging mechanism is not like Ruby Gems.

## License

GNU GPL Version 2.
