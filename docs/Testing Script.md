# Octave.app Testing Script

This is a list of actions the maintainer needs to do to test a build of Octave.app.

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
