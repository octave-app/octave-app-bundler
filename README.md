octave-app-bundler
==================

This repository contains the necessary files to build Octave.app (version >4) using Homebrew. Most users should either download the binary or use a package manager as described [here](http://wiki.octave.org/Octave_for_MacOS_X).

More information at http://wiki.octave.org/Create_a_MacOS_X_App_Bundle_Using_Homebrew.

## Contact

This project is maintained by the [octave-app Organization](https://github.com/octave-app).
[Sebastian Schoeps](https://github.com/schoeps) developed the original code. [Andrew Janke](https://github.com/apjanke) is a co-maintainer.

The home repo for this project is [octave-app/octave-app-bundler on GitHub](https://github.com/octave-app/octave-app-bundler). Please report any bugs on the Issue Tracker there.

Homebrew formulae used for Octave.app are in the [octave-app/octave-app tap](https://github.com/octave-app/homebrew-octave-app).

## How it works

Octave-app-bundler uses Homebrew to build and install Octave and all its dependencies. This is done in a separate Homebrew prefix under the target application so it doesn't interfere with any existing Homebrew installations. It then bundles those programs as a macOS app bundle, and creates an installer DMG using andreyvit's [create-dmg tool](https://github.com/andreyvit/create-dmg).

## Usage

Again, if you just want to use Octave, you should [download the pre-built binary](http://wiki.octave.org/Octave_for_MacOS_X) instead of running octave-app-bundler yourself.

For those who do want to bundle their own Octave.app:

Clone the [repo](https://github.com/octave-app/octave-app-bundler), `cd` to it, and run `./bundle_octave`. The defaults will build an app using a recent version of Octave.

`bundle_octave` does have options, but they're mainly for use in debugging `bundle_octave` itself. They're not recommended for users, so avoid them unless you have a specific reason to use one. For details on the options, see `./bundle_octave --help`.
