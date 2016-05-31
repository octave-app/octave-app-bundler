#!/bin/bash -e

# ask the user about feautures
if [ "$1" != "defaults" ]; then
	read -p "In which directory do you want Octave to be installed? [/Applications/Octave.app]: " install_dir
	read -p "Do you want to build the GUI? [Y/n]: " build_gui
	read -p "Do you want to build a development snapshot [y/N]: " build_devel
	read -p "Do you want to create a DMG image? [Y/n]: " build_dmg
	read -p "Where do you want to store the DMG? [$HOME]: " dmg_dir
fi

# set default values if nothing has been specified
install_dir=${install_dir:-"/Applications/Octave.app"}
build_gui=${build_gui:-y}
build_devel=${build_devel:-n}
build_dmg=${build_dmg:-y}
dmg_dir=${dmg_dir:-$HOME}
upload_dmg=${build_dmg:-y}
with_test=${with_test:-y}

# set some environment variables
export HOMEBREW_BUILD_FROM_SOURCE=1
PATH="$install_dir/Contents/Resources/usr/bin/:$PATH"

# check if we do full or update
if [ -e "$install_dir/Contents/Resources/usr/bin/brew" ]; then
	echo "Update."
	install_type='update'
else
	install_type='full'
fi
	
if [ "$install_type" == "update" ]; then
	# uninstall octave and update formulas
	echo "Update homebrew installation in $install_dir."
	cd "$install_dir/Contents/Resources/usr/bin"
	if [ -d "$install_dir/Contents/Resources/usr/Cellar/octave" ]
	then
		./brew uninstall octave # remove octave because we always recompile
	fi
	./brew update # get new formulas
	./brew upgrade # compile new formulas
	./brew cleanup # remove old versions
else
	# install homebrew
	echo "Create new homebrew installation in $install_dir."
	osacompile -o "$install_dir" -e " "
	mkdir -p "$install_dir/Contents/Resources/usr"
	curl -L https://github.com/Homebrew/homebrew/tarball/master | tar xz --strip 1 -C "$install_dir/Contents/Resources/usr"
fi

# be conservative regarding architectures
# use Mac's (BSD) sed
/usr/bin/sed -i '' 's/march=native/march=core2/g' "$install_dir/Contents/Resources/usr/Library/Homebrew/extend/ENV/super.rb" 
/usr/bin/sed -i '' 's/march=native/march=core2/g' "$install_dir/Contents/Resources/usr/Library/Homebrew/extend/ENV/std.rb" 

# go to the bin directory 
cd "$install_dir/Contents/Resources/usr/bin"

# install trash command line utility
./brew install trash

# install Qscintilla2 without python bindings
./brew install qscintilla2 --without-python --without-plugin

# install gcc and set FC
./brew install gcc
export FC="$install_dir/Contents/Resources/usr/bin/gfortran"

# get scietific libraries
./brew tap homebrew/science
./brew install graphicsmagick --with-quantum-depth-16
./brew install ghostscript

# we prefer openblas over Apple's BLAS implementation
./brew install arpack --with-openblas
./brew install qrupdate --with-openblas
./brew install suite-sparse --with-openblas

# use github mirror to gnuplot 5.1 (devel)
./brew install gnuplot --with-qt --with-cairo --universal --HEAD

# enforce fltk (without fltk all native graphics is disabled and
# e.g. gl2ps is not used. This will be untangled in Octave 4.2)
# we use devel because fltk 1.3.3 does not work on recent Mac OS
./brew install fltk --devel

# icoutils
./brew install icoutils

# create path for ghostscript
gs_ver="$(./gs --version)"
export GS_OPTIONS="-sICCProfilesDir=$install_dir/Contents/Resources/usr/opt/ghostscript/share/ghostscript/$gs_ver/iccprofiles/ -sGenericResourceDir=$install_dir/Contents/Resources/usr/opt/ghostscript/share/ghostscript/$gs_ver/Resource/ -sFontResourceDir=$install_dir/Contents/Resources/usr/opt/ghostscript/share/ghostscript/$gs_ver/Resource/Font"

# get newest octave formula, currently (4.0.2) this is not needed
# curl https://raw.githubusercontent.com/schoeps/homebrew-science/octave/octave.rb -o "$install_dir/Contents/Resources/usr/Library/Taps/homebrew/homebrew-science/octave.rb"

# build octave
octave_settings="--build-from-source --without-java --universal --with-audio --with-openblas --without-fltk --verbose --debug"
if [ "$build_devel" == "y" ]; then
	octave_settings="$octave_settings --devel"
fi
if [ "$build_gui" == "y" ]; then
	octave_settings="$octave_settings --with-gui"
fi
if [ "$with_test" == "n" ]; then
       octave_settings="$octave_settings --without-test"
fi

# Quick hack to get the newest octave formula
# from Sebastian's github repository
# curl https://raw.githubusercontent.com/schoeps/homebrew-science/octave/octave.rb -o "$install_dir/Contents/Resources/usr/Library/Taps/homebrew/homebrew-science/octave.rb"

# finally build octave
./brew install octave $octave_settings

# get versions
oct_ver="$(./octave --version | /usr/bin/sed -n 1p | /usr/bin/grep -o '\d\..*$' )"
oct_ver_string="$(./octave --version | /usr/bin/sed -n 1p)"
oct_copy="$(./octave --version | /usr/bin/sed -n 2p | /usr/bin/cut -c 15- )"

# rebuilding fontconfig from source seems to fix gnuplot font problems
./brew uninstall fontconfig
./brew install fontconfig --build-from-source

# remove unnecessary files installed due to wrong dependencies
if [ -d "$install_dir/Contents/Resources/usr/Cellar/pyqt" ]; then
	./brew uninstall pyqt
fi
if [ -d "$install_dir/Contents/Resources/usr/Cellar/veclibfort" ]; then
	./brew uninstall veclibfort
fi

# create applescript to execute octave
tmp_script=$(mktemp /tmp/octave-XXXX);
echo 'on export_gs_options()' > $tmp_script
echo '  return "export GS_OPTIONS=\"-sICCProfilesDir='$install_dir'/Contents/Resources/usr/opt/ghostscript/share/ghostscript/'$gs_ver'/iccprofiles/ -sGenericResourceDir='$install_dir'/Contents/Resources/usr/opt/ghostscript/share/ghostscript/'$gs_ver'/Resource/ -sFontResourceDir='$install_dir'/Contents/Resources/usr/opt/ghostscript/share/ghostscript/'$gs_ver'/Resource/Font\";"' >> $tmp_script
#echo '  return "export GS_OPTIONS=\"'$GS_OPTIONS'\""' >> $tmp_script
echo 'end export_gs_options' >> $tmp_script
echo '' >> $tmp_script
echo 'on export_gnuterm()' >> $tmp_script
echo '  return "export GNUTERM=\"qt\";"'  >> $tmp_script
echo "end export_gnuterm"  >> $tmp_script
echo '' >> $tmp_script
echo 'on export_path()' >> $tmp_script
echo '  return "export PATH=\"'$install_dir'/Contents/Resources/usr/bin/:$PATH\";"' >> $tmp_script
echo 'end export_path'  >> $tmp_script
echo '' >> $tmp_script
echo 'on export_dyld()' >> $tmp_script
echo '  return "export DYLD_FALLBACK_LIBRARY_PATH=\"'$install_dir'/Contents/Resources/usr/lib:/lib:/usr/lib\";"' >> $tmp_script
echo 'end export_dyld'  >> $tmp_script
echo '' >> $tmp_script
echo 'on run_octave_gui()' >> $tmp_script
echo '  return "cd ~;clear;'$install_dir'/Contents/Resources/usr/bin/octave --force-gui | logger 2>&1;"' >> $tmp_script
echo 'end run_octave_gui'  >> $tmp_script
echo '' >> $tmp_script
echo 'on run_octave_cli()' >> $tmp_script
echo '  return "cd ~;clear;'$install_dir'/Contents/Resources/usr/bin/octave;exit;"' >> $tmp_script
echo 'end run_octave_cli'  >> $tmp_script
echo '' >> $tmp_script
echo 'on run_octave_open(filename)' >> $tmp_script
echo '  return "cd ~;clear;'$install_dir'/Contents/Resources/usr/bin/octave --persist --eval \"edit " & filename & "\" | logger 2>&1;"' >> $tmp_script
echo 'end run_octave_open'  >> $tmp_script
echo '' >> $tmp_script
echo 'on path_check()' >> $tmp_script
echo '  if not (POSIX path of (path to me) contains "'$install_dir'") then' >> $tmp_script
echo '    display dialog "Please run Octave from the '$install_dir' folder" with icon stop with title "Error" buttons {"OK"}' >> $tmp_script
echo '    error number -128' >> $tmp_script
echo '  end if' >> $tmp_script
echo 'end path_check' >> $tmp_script
echo '' >> $tmp_script
echo 'on open argv' >> $tmp_script
echo 'path_check()' >> $tmp_script
echo 'set filename to "\"" & POSIX path of item 1 of argv & "\""' >> $tmp_script
echo '  set cmd to export_gs_options() & export_gnuterm() & export_path() & export_dyld() & run_octave_open(filename)' >> $tmp_script
echo '  do shell script cmd' >> $tmp_script
echo 'end open'  >> $tmp_script
echo '' >> $tmp_script
echo 'on run' >> $tmp_script
echo '  path_check()' >> $tmp_script
if [ "$build_gui" == "y" ]; then
	echo '  set cmd to export_gs_options() & export_gnuterm() & export_path() & export_dyld() & run_octave_gui()' >> $tmp_script
	echo '  do shell script cmd' >> $tmp_script
else
	echo '  set cmd to export_gs_options() & export_gnuterm() & export_path() & run_octave_cli()' >> $tmp_script
	echo '  tell application "Terminal"' >> $tmp_script
	echo '    activate' >> $tmp_script
	echo '    do script cmd' >> $tmp_script
	echo '  end tell' >> $tmp_script
fi
echo "end run" >> $tmp_script
osacompile -o $install_dir/Contents/Resources/Scripts/main.scpt $tmp_script

# create a nice iconset (using the icons shipped with octave)
# the following might fail for the development version
hicolor="$install_dir/Contents/Resources/usr/opt/octave/share/icons/hicolor"
svg_icon="$hicolor/scalable/apps/octave.svg"
tmp_iconset="$(mktemp -d /tmp/iconset-XXXX)/droplet.iconset"
mkdir -p "$tmp_iconset"
cp "$hicolor/16x16/apps/octave.png" "$tmp_iconset/icon_16x16.png"
cp "$hicolor/32x32/apps/octave.png" "$tmp_iconset/icon_16x16@2x.png"
cp "$hicolor/32x32/apps/octave.png" "$tmp_iconset/icon_32x32.png"
cp "$hicolor/64x64/apps/octave.png" "$tmp_iconset/icon_32x32@2x.png"
cp "$hicolor/128x128/apps/octave.png" "$tmp_iconset/icon_128x128.png"
cp "$hicolor/256x256/apps/octave.png" "$tmp_iconset/icon_128x128@2x.png"
cp "$hicolor/256x256/apps/octave.png" "$tmp_iconset/icon_256x256.png"
cp "$hicolor/512x512/apps/octave.png" "$tmp_iconset/icon_256x256@2x.png"
cp "$hicolor/512x512/apps/octave.png" "$tmp_iconset/icon_512x512.png"
iconutil -c icns -o "$install_dir/Contents/Resources/applet.icns" "$tmp_iconset"

# create or update entries in the application's plist
defaults write "$install_dir/Contents/Info" NSUIElement 1
defaults write "$install_dir/Contents/Info" CFBundleIdentifier org.octave.Octave 
defaults write "$install_dir/Contents/Info" CFBundleShortVersionString "$oct_ver"
defaults write "$install_dir/Contents/Info" CFBundleVersion "$oct_ver_string"
defaults write "$install_dir/Contents/Info" NSHumanReadableCopyright "$oct_copy"
defaults write "$install_dir/Contents/Info" CFBundleDocumentTypes -array '{"CFBundleTypeExtensions" = ("m"); "CFBundleTypeOSTypes" = ("Mfile"); "CFBundleTypeRole" = "Editor";}'    
plutil -convert xml1 "$install_dir/Contents/Info.plist"
chmod a=r "$install_dir/Contents/Info.plist"

# add icon to octave-gui
if [ "$build_gui" == "y" ]; then
	export python_script=$(mktemp /tmp/octave-XXXX);
	echo '#!/usr/bin/env python' > $python_script
	echo 'import Cocoa' >> $python_script
	echo 'import sys' >> $python_script
	echo 'Cocoa.NSWorkspace.sharedWorkspace().setIcon_forFile_options_(Cocoa.NSImage.alloc().initWithContentsOfFile_(sys.argv[1].decode("utf-8")), sys.argv[2].decode("utf-8"), 0) or sys.exit("Unable to set file icon")' >> $python_script
	python "$python_script" "$install_dir/Contents/Resources/applet.icns" $install_dir/Contents/Resources/usr/Cellar/octave/*/libexec/octave/*/exec/*/octave-gui
fi

# collect dependencies from the homebrew database
# clean up the strings using sed
echo "" > "$install_dir/Contents/Resources/DEPENDENCIES"

# force all formulas to be linked and list them in 
# the file DEPENDENCIES
./brew list -1 | while read line
do
	./brew unlink $line
	./brew link --force $line
	./brew info $line | /usr/bin/sed -e 's$homebrew/science/$$g'| /usr/bin/sed -e 's$: .*$$g' | /usr/bin/sed -e 's$/Applications.*$$g' | /usr/bin/head -n3 >> "$install_dir/Contents/Resources/DEPENDENCIES"
	echo "" >> "$install_dir/Contents/Resources/DEPENDENCIES"
done

# create a nice dmg disc image with create-dmg (MIT License)
if [ "$build_dmg" == "y" ]; then
	# get make-dmg from github
	tmp_dir=$(mktemp -d /tmp/octave-XXXX)
	git clone https://github.com/schoeps/create-dmg.git $tmp_dir/create-dmg

	# get background image
	curl https://raw.githubusercontent.com/schoeps/octave_installer/master/background.tiff -o "$tmp_dir/background.tiff"

	# Put existing dmg into Trash
	if [ -f "$dmg_dir/Octave-Installer.dmg" ]; then
	  echo "Moving $dmg_dir/Octave_Installer.dmg into the trash"
	  ./trash "$dmg_dir/Octave-Installer.dmg"
	fi

	# running create-dmg; this may issue warnings if run headless. However, the dmg
	# will still be created, only some beautifcation cannot be applied
	cd "$tmp_dir/create-dmg"
	./create-dmg \
	--volname "Octave-Installer" \
	--volicon "$install_dir/Contents/Resources/applet.icns" \
	--window-size 550 442 \
	--icon-size 48 \
	--icon Octave.app 125 180 \
	--hide-extension Octave.app \
	--app-drop-link 415 180 \
	--eula "$install_dir/Contents/Resources/usr/opt/octave/README" \
	--add-file COPYING "$install_dir/Contents/Resources/usr/opt/octave/COPYING" 126 300 \
	--add-file DEPENDENCIES "$install_dir/Contents/Resources/DEPENDENCIES" 415 300 \
	--disk-image-size 1400 \
	--background "$tmp_dir/background.tiff" \
	"$dmg_dir/Octave-Installer.dmg" \
	"$install_dir" 

	echo DMG ready: $dmg_dir/Octave-Installer.dmg
fi