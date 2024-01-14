#!/usr/bin/env bash
#
# create-monterey-iso.sh - Create a macOS 12 installer ISO from the installer app
#
# I use this to create an ISO that VMware Fusion can use to create a macOS 12 VM. It doesn't
# seem to be able to directly use the Install macOS Monterey.app installer.
#
# For this to work, you must download the macOS Monterey installer from the Mac App Store so
# it's in your /Applications folder.
#
# I ganked this from https://gist.github.com/memoryleak/30f275beebe28595d736eb2b380a0fa9 on 2024-01-12.
# Tested on a macOS 14 Intel host running VMware Fusion 13.5.0.

# TODO: Reduce DMG size and/or enable compression?
# TODO: Factor out names, and jankobashify this.

sudo hdiutil create -o /tmp/Monterey -size 16g -volname Monterey -layout SPUD -fs HFS+J
sudo hdiutil attach /tmp/Monterey.dmg -noverify -mountpoint /Volumes/Monterey
sudo '/Applications/Install macOS Monterey.app/Contents/Resources/createinstallmedia' --volume /Volumes/Monterey --nointeraction
hdiutil eject -force '/Volumes/Install macOS Monterey'
hdiutil convert /tmp/Monterey.dmg -format UDTO -o ~/Downloads/Monterey
mv -v ~/Downloads/Monterey.cdr ~/Downloads/Monterey.iso
sudo rm -fv /tmp/Monterey.dmg
