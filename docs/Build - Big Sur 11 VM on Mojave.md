# Big Sur on Mojave

This document is a sloppy collection of notes on how to build a macOS 11 Big Sur version of Octave.app using a VMware VM on macOS 10.14 Mojave running on an Intel Mac.

This is useful to me because I still run 10.14 Mojave on my main Macs, and don't have an Intel Mac running a newer version of macOS>

## References

* Main articles I based this on.
  * <https://graspingtech.com/vmware-fusion-macos-big-sur/>
  * <https://graspingtech.com/create-bootable-macos-iso/>

## Process

You need to download the macOS 11 Big Sur installer app, then use it to create a bootable installer in a DMG image, and then convert it to an ISO.

First, download the installer using the app store. Click the "Download" button. When the installer program pops up and wants to upgrade your local box, quit it. Then copy the `Install macOS Big Sur.app` thing from `/Applications` to `/Downloads`.

Then make an installmedia DMG using on-main disk stuff:

1. `hdiutil create -o /tmp/macos-big-sur-installer -size 12945m -volname macOS -layout SPUD -fs HFS+J`
1. `hdiutil attach /tmp/macos-big-sur-installer.dmg -noverify -mountpoint /Volumes/macOS`
1. `cd ~/Downloads`
1. `sudo ./Install\ macOS\ Big\ Sur.app/Contents/Resources/createinstallmedia --volume /Volumes/big-sur-installer --nointeraction`
1. Unmount: `hdiutil detach -force /Volumes/Install macOS Big Sur`
    1. I don't know why the file name changed here!
1. Convert the DMG to an ISO
    1. `hdiutil convert /tmp/macos-big-sur-installer.dmg -format UDTO -o ~/Downloads/macos-big-sur`
    1. `mv ~/Downloads/macos-big-sur.cdr ~/Downloads/macos-big-sur.iso`

Then, create the VM. As of 2023-03-10, I'm using vmWare Fusion 11.5.7, which is the latest version that still runs on macOS 10.14.

When you drag the Big Sur installer to the "Create from disk" thingie in the Create VM wizard, it doesn't recognize macOS 11. You get the manual OS version selection dialog. The latest version there, for me, is macOS 10.15. Selected that.

## Progress

### 2023-03-11 - First Attempt

Making a VM on angharad, my Intel iMac Pro running 10.14 Mojave. "xbiggie". ("biggie" for "Big Sur", "x" for "x86".) 10 "cores", 8192 MB. Autodetect bridged networking. Disk: 80 GB, split into multiple files. Defaults for all other options.

Xcode 13.2.1 is the last Xcode supported for macOS 11. Downloading it from the App Store in the VM didn't work. (Gave me an error saying it needed a newer macOS version.) Downloaded the .xip from the developer.apple.com website instead.

Well, that apparently didn't work. I got through setting up the OS, running updates, and installing Xcode, and now the VM just freezes soon after I launch it each time. ...or, maybe it did, and GUI responsiveness is just so slow it's unusable? Eventually I got to the point where I could clode the octave-app-bundler repo and fire off a build, but it just sits there at "Pouring portable-ruby-..." for like an hour or two until I get tired of it.

```text
janke@xbiggie octave-app-bundler % ./bundle_octave
Building Octave-8.1.0.app at /Applications/Octave-8.1.0.app from formula octave-octave-app@8.1.0
Creating new staged app build at /Applications/Octave-8.1.0.app
Creating new Homebrew installation in /Applications/Octave-8.1.0.app/Contents/Resources/usr
Cloning into '/Applications/Octave-8.1.0.app/Contents/Resources/usr/Homebrew'...
remote: Enumerating objects: 231738, done.
remote: Counting objects: 100% (149/149), done.
remote: Compressing objects: 100% (126/126), done.
remote: Total 231738 (delta 31), reused 99 (delta 21), pack-reused 231589
Receiving objects: 100% (231738/231738), 66.85 MiB | 26.06 MiB/s, done.
Resolving deltas: 100% (170239/170239), done.
Warning: ruby is a developer command, so Homebrew's
developer mode has been automatically turned on.
To turn developer mode off, run:
  brew developer off

==> Downloading https://ghcr.io/v2/homebrew/portable-ruby/portable-ruby/blobs/sha256:1f50bf80583bd436c9542d4fa5ad47df0ef0f0bea22ae710c4f04c42d7560bca
Already downloaded: /Users/janke/Library/Caches/Homebrew/portable-ruby-2.6.8_1.el_capitan.bottle.tar.gz
==> Pouring portable-ruby-2.6.8_1.el_capitan.bottle.tar.gz
```

Well, that just doesn't work. I let it run for over a day and it just sat there at "Pouring portable-ruby". And the VM feels really slow in UI interaction. Time to try on a box running a newer macOS, I think.
