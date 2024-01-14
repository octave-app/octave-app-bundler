# Octave.app Testing Script

This is a list of actions the maintainer needs to do to test a build of Octave.app. It's not exhaustive, but it seems like a good start.

You can test it initially on the same computer you built it on as a quick first check, but a real test needs to be done on a "clean" testbed computer, to make sure the build isn't depending on other things installed on your dev machine. The clean test machine should be one with a fresh macOS install and nothing else. Then optionally one with Homebrew and some of its packages installed, to see if there are conflicts with that.

For a true test, you also need to test it from a download of the installer posted to GitHub Releases (or wherever else we host it), because that download process itself can break things!

## Steps

### Prepare

* Make sure the existing /Applications/Octave-&lt;version>.app is deleted.

### Install

* Double-click the Octave-&lt;version>.dmg file to open it.
* Double-click the COPYING file; verify that it opens and is readable.
* Double-click the DEPENDENCIES file.
  * Verify that it opens and is readable.
  * Check the Octave version string at the top to make sure it makes sense.
* Drag the Octave icon to the Applications folder link in the DMG to install it.

### Run

* Double-click /Applications/Octave-&lt;version>.app to run it.
* Run `__run_test_suite__` in the command window to run the full suite of unit tests. Check that they all pass.
  * XFAIL: The tar test is failing as of June 2018; we think this is acceptable.

* Run each of the following plotting commands, and see that their output looks reasonable. (E.g. visible, not half-size within the figure window, and so on.)

```matlab
sombrero
surf(peaks)
```

*TODO*: Come up with more tests.
