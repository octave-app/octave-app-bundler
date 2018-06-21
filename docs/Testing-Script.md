Octave.app Testing Script
=========================

This is a list of actions the maintainer needs to do to test a build of Octave.app.

# Steps

## Prepare

* Make sure the existing /Applications/Octave-&lt;version>.app is deleted.

## Install

* Double-click the Octave-&lt;version>.dmg file to open it.
* Double-click the COPYING file; verify that it opens and is readable.
* Double-click the DEPENDENCIES file.
  * Verify that it opens and is readable.
  * Check the Octave version string at the top to make sure it makes sense.
* Drag the Octave icon to the Applications folder link in the DMG to install it.

## Run

* Double-click /Applications/Octave-&lt;version>.app to run it.

*TODO*: Come up with more tests.
