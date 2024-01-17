# Octave.app Build Environment

Octave.app uses a clean, dedicated VM as a build environment.

It is built on OS X 10.11 El Capitan with Xcode 8.2.1.
This older OS is used so that the build app supports all macOS versions going that far back.
(Building it on a newer version of macOS would require users to run that version.
Unless we can figure out how to use target API versions to target an older macOS SDK while building on a newer macOS.)

## Creating a build box

NOTE: This is out of date, because as of 2023-01, Homebrew no longer supports OS X 10.11. You need macOS 11 or later.

This describes in detail how I set up my build box.
This is done using VMware Fusion.
You can probably get it to work with Parallels or VirtualBox, too.

* Install VMware Fusion.
* Acquire the OS X 10.11 El Capitan installer.
  * This is no longer downloadable from Apple, so you will need to find someone who has a copy lying around. Andrew has one.
* Create a new VM using the OS X 10.11 installer image.
  * Customize the VM's settings.
    * Name it something memorable. I like to have my VM names start with the same letters as the macOS version, so I'll name it “elke” or something similar.
    * Increase the disk size to 80 GB.
      * Do not make it smaller. You'll run out of space.
      * Do not make it larger. You'll use up more of your host OS's disk space due to data block churn.
    * Increase the CPUs to 4 vCPUs or more. (Preferably much more.)
* Run the OS installer by powering up the VM.
  * Before running the installer itself, run Disk Utility and use it to re-partition the disk so all available space is used by the main “Mac HD” partition.
* Install stuff on the guest OS.
  * Install Xcode 8.2.1.
    * Run it once manually to accept the license agreement and install the command line tools.
  * Install MacTeX.
  * Do not install Homebrew!
  * Actually, no: *do* install Homebrew, because you will need it to get `gsed` and some other dev tools which `bundle_octave` depends on. Sorry. Then install this brewd stuff:
    * `brew install gsed`

Then set up the build script by cloning the `octave-app-bundler` repo.

```bash
cd ~
mkdir -p repos
cd repos
git clone https://github.com/octave-app/octave-app-bundler
```

Now you can `cd ~/repos/octave-app-bundler` and run `./bundle_octave` to build Octave.app.

## Historical Build Environments

We have a policy of supporting the last three versions of macOS available at the time of an Octave release, because that's as far back as Homebrew itself supports.

Octave.app 4.4.0 and 4.4.1 were built on OS X 10.11 El Capitan with Xcode 8.2.1.

Octave.app 5.1.0 and later are looking to build on macOS 10.12 with Xcode 9.2, but it isn't working yet. (See <https://github.com/octave-app/octave-app-bundler/issues/75>.)