#!/bin/sh

# determine install dir
if [ "$1" != "defaults" ]; then
	read -p "In which directory do you want Octave to be installed? [/Applications/Octave.app]: " install_dir
fi
install_dir=${install_dir:-"/Applications/Octave.app"}

# check if 
if [ -d "$install_dir" ]; then
	echo "Directory $install_dir exists. Please remove it, e.g."
	echo "> rm -rf $install_dir"
	exit;
fi

# ask the user about feautures
if [ "$1" != "defaults" ]; then
	read -p "Do you want to build the GUI? [Y/n]: " build_gui
	read -p "Do you want to build a development snapshot [y/N]: " build_devel
	read -p "Do you want to create a DMG image? [y/N]: " build_dmg
	read -p "Where do you want to store the DMG? [$HOME]: " dmg_dir
fi

# set default values if nothing has been specified
build_gui=${build_gui:-y}
build_devel=${build_devel:-n}
build_dmg=${build_dmg:-y}
dmg_dir=${dmg_dir:-$HOME}

# create applescript for starting. The cli version starts a terminal session.
# A future applescript could check whether cl-tools are installed or set gnuterm settings
tmp_script=$(mktemp /tmp/octave-XXXX);
if [ "$build_gui" == "y" ]; then
cat >"$tmp_script" <<EOF
on open argv
path_check()
set filename to "'" & POSIX path of item 1 of argv & "'"
do shell script "export GNUTERM='qt';export PATH=/Applications/Octave.app/Contents/Resources/usr/bin/:\$PATH;cd ~;/Applications/Octave.app/Contents/Resources/usr/bin/octave --force-gui --persist --eval \"edit " & filename & "\" | logger 2>&1"
end open
on run
path_check()
do shell script "export GNUTERM='qt';export PATH=/Applications/Octave.app/Contents/Resources/usr/bin/:\$PATH;cd ~;/Applications/Octave.app/Contents/Resources/usr/bin/octave --force-gui  | logger 2>&1"
end run
on path_check()
if not (POSIX path of (path to me) contains "/Applications/Octave.app") then
display dialog "Please run Octave from the '/Applications' folder" with icon stop with title "Error" buttons {"OK"}
error number -128
end if
end path_check
EOF
else
cat >"$tmp_script" <<EOF
on run
path_check()
tell application "Terminal"
do script "export GNUTERM='qt';export PATH=/Applications/Octave.app/Contents/Resources/usr/bin/:\$PATH;cd ~;clear;octave"
activate
end tell
end run
on path_check()
if not (POSIX path of (path to me) contains "/Applications/Octave.app") then
display dialog "Please run Octave from the '/Applications' folder" with icon stop with title "Error" buttons {"OK"}
error number -128
end if
end path_check
EOF
fi

# create appbundle
osacompile -o"$install_dir" "$tmp_script"

# install brew
mkdir -p "$install_dir/Contents/Resources/usr"
curl -L https://github.com/Homebrew/homebrew/tarball/master | tar xz --strip 1 -C "$install_dir/Contents/Resources/usr"

# be conservative regarding architectures
sed -i '' 's/march=native/march=core2/g' "$install_dir/Contents/Resources/usr/Library/Homebrew/extend/ENV/super.rb" 
sed -i '' 's/march=native/march=core2/g' "$install_dir/Contents/Resources/usr/Library/Homebrew/extend/ENV/std.rb" 

# start compiling
cd "$install_dir/Contents/Resources/usr/bin"
./brew tap homebrew/science
./brew install imagemagick --with-librsvg
./brew install graphicsmagick --with-quantum-depth-16

# we prefer openblas over Apple's BLAS implementation
./brew install arpack --with-openblas
./brew install qrupdate --with-openblas
./brew install suite-sparse421 --with-openblas

# use github mirror to gnuplot 5.1 (devel)
./brew install gnuplot --with-qt --with-cairo --universal --verbose --HEAD

# get newest octave formula and then build octave
curl https://raw.githubusercontent.com/schoeps/homebrew-science/octave4r3/octave.rb -o "$install_dir/Contents/Resources/usr/Library/Taps/homebrew/homebrew-science/octave.rb"
octave_settings="--build-from-source --without-java --universal --with-audio --with-openblas"
if [ "$build_devel" == "y" ]; then
	octave_settings="$octave_settings --devel"
fi
if [ "$build_gui" == "y" ]; then
	octave_settings="$octave_settings --with-gui"
fi
./brew install octave $octave_settings

# get octave version
oct_ver="$(./octave --version |sed -n 1p |grep -o '\d\..*$' )"
oct_ver_string="$(./octave --version | sed -n 1p)"
oct_copy="$(./octave --version | sed -n 2p | cut -c 15- )"

# rebuilding fontconfig from source seems to fix gnuplot font problems
./brew uninstall fontconfig
./brew install fontconfig --build-from-source

# create a nice iconset (the octave icons in "share/icons" are not reliable)
svg_icon="$install_dir/Contents/Resources/usr/opt/octave/share/icons/hicolor/scalable/apps/octave.svg"
tmp_iconset="$(mktemp -d /tmp/iconset-XXXX)/droplet.iconset"
mkdir -p "$tmp_iconset"
./convert -background none -resize 16x16 "$svg_icon" "$tmp_iconset/icon_16x16.png"
./convert -background none -resize 32x32 "$svg_icon" "$tmp_iconset/icon_16x16@2x.png"
./convert -background none -resize 32x32 "$svg_icon" "$tmp_iconset/icon_32x32.png"
./convert -background none -resize 64x64 "$svg_icon" "$tmp_iconset/icon_32x32@2x.png"
./convert -background none -resize 128x128 "$svg_icon" "$tmp_iconset/icon_128x128.png"
./convert -background none -resize 256x256 "$svg_icon" "$tmp_iconset/icon_128x128@2x.png"
./convert -background none -resize 256x256 "$svg_icon" "$tmp_iconset/icon_256x256.png"
./convert -background none -resize 512x512 "$svg_icon" "$tmp_iconset/icon_256x256@2x.png"
./convert -background none -resize 512x512 "$svg_icon" "$tmp_iconset/icon_512x512.png"
./convert -background none -resize 1024x1024 "$svg_icon" "$tmp_iconset/icon_512x512@2x.png"
iconutil -c icns -o "$install_dir/Contents/Resources/octave.icns" "$tmp_iconset"

# modify some entries in the Application plist
defaults write "$install_dir/Contents/Info" NSUIElement 1
defaults write "$install_dir/Contents/Info" CFBundleIconFile "octave"
defaults write "$install_dir/Contents/Info" CFBundleIdentifier org.octave.Octave 
defaults write "$install_dir/Contents/Info" CFBundleShortVersionString "$oct_ver"
defaults write "$install_dir/Contents/Info" CFBundleVersion "$oct_ver_string"
defaults write "$install_dir/Contents/Info" NSHumanReadableCopyright "$oct_copy"
defaults write "$install_dir/Contents/Info" CFBundleDocumentTypes -array '{"CFBundleTypeExtensions" = ("m"); "CFBundleTypeOSTypes" = ("Mfile"); "CFBundleTypeRole" = "Editor";}'    
plutil -convert xml1 "$install_dir/Contents/Info.plist"
chmod a=r "$install_dir/Contents/Info.plist"

# collect dependencies from the homebrew database
# clean up the strings using sed
touch "$install_dir/Contents/Resources/DEPENDENCIES"
for f in $(./brew deps octave)
do
	./brew info $f | sed -e 's$homebrew/science/$$g'| sed -e 's$: .*$$g' | sed -e 's$/Applications.*$$g' | head -n3 >> "$install_dir/Contents/Resources/DEPENDENCIES"
	echo "" >> "$install_dir/Contents/Resources/DEPENDENCIES"
done

# change owner
# chown -R admin:wheel /Applications/Octave.app/

# create a nice dmg disc image with create-dmg (MIT License)
if [ "build_dmg" == "y" ]; then
	# get make-dmg from github
	tmp_dir=$(mktemp -d /tmp/octave-XXXX)
	git clone https://github.com/schoeps/create-dmg.git $tmp_dir/create-dmg

	# get background image
	#curl xxx -o background.tiff

	# running create-dmg; this may issue warnings if run headless. However, the dmg
	# will still be created, only some beautifcation cannot be applied
	cd $tmp_dir/create-dmg
	./create-dmg \
	--volname "Octave-Installer" \
	--volicon "$install_dir/Contents/Resources/octave.icns" \
	--window-size 550 442 \
	--icon-size 48 \
	--icon Octave.app 125 180 \
	--hide-extension Octave.app \
	--app-drop-link 415 180 \
	--eula "$install_dir/Contents/Resources/usr/opt/octave/README" \
	--add-file COPYING "$install_dir/Contents/Resources/usr/opt/octave/COPYING" 126 300 \
	--add-file DEPENDENCIES "$install_dir/Contents/Resources/DEPENDENCIES" 415 300 \
	--disk-image-size 1250 \
	--background "../background.tiff" \
	"$dmg_dir/Octave-Installer.dmg" \
	"$install_dir" 

	echo DMG ready: $dmg_dir/Octave-Installer.dmg
fi

