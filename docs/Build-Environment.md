Octave.app Build Environment
============================

Octave.app uses a clean, dedicated VM as a build environment.

It is built on OS X 10.11 El Capitan with Xcode 8.2.1.
This older OS is used so that the build app supports all macOS versions going that far back.
(Building it on a newer version of macOS would require users to run that version.
Unless we can figure out how to use target API versions to target an older macOS SDK while building on a newer macOS.)

##  Creating a build box

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
    * Increase the CPUs to 4 vCPUs.
* Run the OS installer by powering up the VM.
  * Before running the installer itself, run Disk Utility and use it to re-partition the disk so all available space is used by the main “Mac HD” partition.
* Install stuff on the guest OS.
  * Install Xcode 8.2.1.
    * Run it once manually to accept the license agreement and install the command line tools.
  * Install MacTeX.
  * Do not install Homebrew!

Then set up the build script by cloning the `octave-app-bundler` repo.

```
mkdir -p local/repos
cd local/repos
git clone https://github.com/octave-app/octave-app-bundler
```

Now you can `cd octave-app-bundler` and run `./bundle_octave` to build Octave.app.
