# Octave.app Build Environment

Octave.app prefers a clean, dedicated VM as a build environment, but should work on a regular machine too, even if it has a regular Homebrew installation in the regular location.

Requirements:

* Xcode and Xcode CLT
* MacTeX
* `gsed` and maybe other GNU tools that don't come with macOS
  * Can be installed with Homebrew or MacPorts

We try to build on the oldest version of macOS that's supported by Homebrew. That's usually two major versions back.

## Creating a build box

NOTE: The versions of maOS, Xcode, etc. are rolling, because Homebrew only supports the last 3 versions of macOS, and that's what Octave.app targets. Build boxes should generally be made using the *oldest* supported version of macOS. E.g. as of 2024-05, macOS 14 is the latest macOS, and macOS 12 is the oldest version currently supported by Homebrew. So we build on macOS 12 (or try to).

This describes in detail how I set up my build boxes. I do this using VMware Fusion. You can probably get it to work with Parallels or VirtualBox, too.

First, create a box, either as a VM, or a bare-metal Mac. For VMs, I use VMware Fusion on Intel, and am searching for a hypervisor on AS, because VMware Fusion doesn't support macOS guests on AS. As of 2024-06, I'm trying UTM, and it seems promising.

On VMware:

* Install VMware Fusion.
* Acquire a macOS installer ISO image for our current build OS.
  * You can build one by downloading the installer app from the app store, and using `tools/create-macos-install-iso.sh` to create an ISO from it.
* Create a new VM using the macOS installer ISO image.
  * Customize the VM's settings during the initial setup.
    * Name it something memorable. I like to have my VM names start with the same letters as the macOS version, so I'll name it e.g. “monty” or something similar for macOS Monterey.
    * Increase the disk size to 120 GB.
      * Do not make it smaller. You'll run out of space.
      * Do not make it larger. You'll more likely use up more of your host OS's disk space due to data block churn.
    * Increase the CPUs to 4 vCPUs or more, and RAM to 8 GB or more.
* Run the OS installer by powering up the VM.
  * Before running the installer itself, run Disk Utility and use it to re-partition the disk so all available space is used by the main “Mac HD” partition.
* Do an OS update.
* Install VMware Tools in the guest OS.
* Configure settings
  * Set host name
    * `name=<name>; for x in HostName LocalHostName ComputerName; do sudo scutil --set $x $name; done`
  * Change power and screen saver settings to not sleep or lock screen for a couple hours.
    * Because when it screen-locks while a build is running, it's really slow and hard to log back in. Rely on the host's locking.
  * UI prefs: Finder, Sound, scroll direction

Once you have a fresh box, turn it into a build box by installing things. (I like to snapshot the fresh VM first.)

* Xcode
  * Versions: 14.2 for macOS 12, latest avail for later macOS
* Xcode CLT
  * With `xcode-select --install`, or a downloaded installer
* MacTeX (TexLive)
  * And then update it using TeX Live Utility
* Homebrew, and (only) the tool packages we need
  * `brew install gsed gnu-tar git git-credential-manager bash`
  * Do _not_ install other brew packages, because they can contaminate the Octave.app build.
* Your favorite editors etc.
  * For me, that's: VS Code, iTerm2, and Chrome.
* Configure your user git settings (name and email) on the guest OS.

When doing this, I like to snapshot the VM once after the initial OS installation, again after installing all the tools except Homebrew, and one last time after installing Homebrew and its packages.

In mid 2024, we had a problem with the latest Xcode and CLT breaking the build for some Homebrew formulae, so you had to specially install older versions. But that got fixed as of 2024-05 or so, and now you can use the default versions again.

Then set up the build script by cloning the `octave-app-bundler` repo.

```bash
cd ~
mkdir -p repos
cd repos
git clone https://github.com/octave-app/octave-app-bundler
```

Now you can `cd ~/repos/octave-app-bundler` and run `./bundle_octave` to build Octave.app.

I usually use `./wip_bundle_*` wrapper scripts instead, to get the options for the build I'm currently working on.

For a test box:

* Install macOS.
* Nothing else. The point is to test Octave.app on the basic-est macOS install.
  * Unless you want to run the Octave test suite, in which case you need to install the Xcode CLT in order to get `makeinfo`, perl, and maybe other commands that the test suite depends on.

### Using UTM

For UTM, at least on AS, you need an "IPSW" restore file to create a new VM. (I think.)

I download my IPSW files through [this index on mrmacintosh.com](https://mrmacintosh.com/apple-silicon-m1-full-macos-restore-ipsw-firmware-files-database/), which I think has links to the official Apple downloads. (The "applecdn" or whatever domains in the URL look legit.)

* MrMacintosh IPSW download index
  * <https://mrmacintosh.com/apple-silicon-m1-full-macos-restore-ipsw-firmware-files-database>

## Historical Build Environments

We have a policy of supporting the last three versions of macOS available at the time of an Octave release, because that's as far back as Homebrew itself supports.

Octave.app 4.4.0 and 4.4.1 were built on OS X 10.11 El Capitan with Xcode 8.2.1.

Octave.app 5.1.0 and later are looking to build on macOS 10.12 with Xcode 9.2, but it isn't working yet. (See <https://github.com/octave-app/octave-app-bundler/issues/75>.)

Octave.app 8.4.0 was being buit with the earliest of macOS 12, 13, or 14 that I could get working. Which turned out to be macOS 14.

As of 2024-03, the builds for Qt, GCC, and maybe other packages were broken under Xcode 15.3 specifically. You need to use older versions of Xcode and the CLT. As of 2024-04-06, that was Xcode 15.2 and Xcode CLT 15.1. You need to get them from [Apple's Developer Downloads page](https://developer.apple.com/download/all/?q=xcode), not the App Store, and not `sudo xcode-select --install`. If you already have the latest CLT installed, you must [remove it manually](https://github.com/Homebrew/homebrew-core/issues/162714#issuecomment-2027462141) with `sudo rm -rf /Library/Developer/CommandLineTools` before installing the 15.1 CLT. This got fixed some time in 2024-04 or 2024-05, and is no longer needed.
