# Octave.app Build Environment

Octave.app prefers a clean, dedicated VM as a build environment, but should work on a regular machine too, even if it has a regular Homebrew installation in the regular location.

Requirements:

* Xcode (not 15.3)
* Xcode CLT (not 15.3)
* MacTeX
* `gsed` and maybe other GNU tools
  * Can be installed with Homebrew

We try to build on the oldest version of macOS that's supported by Homebrew. That's usually two major versions back.

As of 2024-03, the builds for Qt, GCC, and maybe other packages are broken under Xcode 15.3 specifically. You need to use older versions. As of 2024-04-06, that's Xcode 15.2 and Xcode CLT 15.1. You need to get them from [Apple's Developer Downloads page](https://developer.apple.com/download/all/?q=xcode), not the App Store, and not `sudo xcode-select --install`. If you already have the latest CLT installed, you must [remove it manually](https://github.com/Homebrew/homebrew-core/issues/162714#issuecomment-2027462141) with `sudo rm -rf /Library/Developer/CommandLineTools` before installing the 15.1 CLT.

## Creating a build box

NOTE: This is out of date, because as of 2023-01, Homebrew no longer supports OS X 10.11. You need macOS 11 or later.

This describes in detail how I set up my build box. This is done using VMware Fusion. You can probably get it to work with Parallels or VirtualBox, too.

* Install VMware Fusion.
* Acquire the macOS 12 Monterey installer.
* Create a new VM using the macOS 12 installer image.
  * Customize the VM's settings.
    * Name it something memorable. I like to have my VM names start with the same letters as the macOS version, so I'll name it “monty” or something similar.
    * Increase the disk size to 80 GB.
      * Do not make it smaller. You'll run out of space.
      * Do not make it larger. You'll likely use up more of your host OS's disk space due to data block churn.
    * Increase the CPUs to 4 vCPUs or more, and RAM to 8 GB or more.
* Run the OS installer by powering up the VM.
  * Before running the installer itself, run Disk Utility and use it to re-partition the disk so all available space is used by the main “Mac HD” partition.
* Install stuff on the guest OS.
  * Install Xcode CLT 15.1.
    * (With the downloaded installer, not `xcode-select --install`.)
  * Install Xcode 15.2.
    * Run it once manually to accept the license agreement.
  * Install MacTeX.
  * Install Homebrew.
    * Then `brew install gsed`

Then set up the build script by cloning the `octave-app-bundler` repo.

```bash
cd ~
mkdir -p repos
cd repos
git clone https://github.com/octave-app/octave-app-bundler
```

Now you can `cd ~/repos/octave-app-bundler` and run `./bundle_octave` to build Octave.app.

I usually use `./wip_bundle_octave` instead, to get the options for the build I'm currently working on.

For a test box:

* Install macOS
* Nothing else. The point is to test Octave.app on the basic-est macOS install.
* Unless you want to run the Octave test suite, in which case you need to install the Xcode CLT in order to get `makeinfo` and maybe other commands that the test suite depends on.

## Historical Build Environments

We have a policy of supporting the last three versions of macOS available at the time of an Octave release, because that's as far back as Homebrew itself supports.

Octave.app 4.4.0 and 4.4.1 were built on OS X 10.11 El Capitan with Xcode 8.2.1.

Octave.app 5.1.0 and later are looking to build on macOS 10.12 with Xcode 9.2, but it isn't working yet. (See <https://github.com/octave-app/octave-app-bundler/issues/75>.)

Octave.app 8.4.0 is being buit with the earliest of macOS 12, 13, or 14 that I can get working.
