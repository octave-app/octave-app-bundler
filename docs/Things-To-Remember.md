Things to Remember
==================

## Always use customized Qt formulae

Homebrew core's `qt` formula is fine. Except that it mistakenly thinks that it's a relocatable bottle, when it is actually not, due to some baked-in paths in the installation files. So if you try to build Octave.app using Homebrew core's `qt` formula, it will install fine, but it will pour from the bottle instead of building from source, and will be broken when you try to run it, because the bottle actually only works when installed in the default prefix. This can result in the documentation step of the build failing, or the app seeming to build okay, but then just failing to launch when you double-click the icon, for no apparent reason.

Always use one of our customized `qt*` formulae, which will force it to build from source.

I've reported this to Homebrew before, but they don't care, because they don't support non-standard installation prefixes.

