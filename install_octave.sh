#!/bin/sh

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
	./brew uninstall octave # remove octave because we always recompile
	git -C '../' reset --hard origin/master # get a fresh homebrew
	git -C '../Library/Taps/homebrew/homebrew-science/' reset --hard origin/master # get a fresh science repo
	./brew update # get new formulas
	./brew upgrade # compile new formulas
	./brew cleanup # remove old versions
else
	# install homebrew
	echo "Create new homebrew installation in $install_dir."
	osacompile -o /Applications/Octave.app -e " "
	mkdir -p "$install_dir/Contents/Resources/usr"
	curl -L https://github.com/Homebrew/homebrew/tarball/master | tar xz --strip 1 -C "$install_dir/Contents/Resources/usr"
fi

# be conservative regarding architectures
# use Mac's (BSD) sed
/usr/bin/sed -i '' 's/march=native/march=core2/g' "$install_dir/Contents/Resources/usr/Library/Homebrew/extend/ENV/super.rb" 
/usr/bin/sed -i '' 's/march=native/march=core2/g' "$install_dir/Contents/Resources/usr/Library/Homebrew/extend/ENV/std.rb" 

# go to the bin directory 
cd "$install_dir/Contents/Resources/usr/bin"

if [ "$install_type" == "full" ]; then
	# start compiling
	./brew tap homebrew/science
	./brew install imagemagick --with-librsvg
	./brew install graphicsmagick --with-quantum-depth-16
	./brew install ghostscript
	
	# we prefer openblas over Apple's BLAS implementation
	./brew install arpack --with-openblas
	./brew install qrupdate --with-openblas
	./brew install suite-sparse --with-openblas
	
	# install fig2dev
	./brew install homebrew/x11/imake
	./brew install schoeps/homebrew-xfig/transfig
	
	# use github mirror to gnuplot 5.1 (devel)
	./brew install gnuplot --with-qt --with-cairo --universal --HEAD

	# enforce fltk
	#./brew install fltk
	
	# icoutils
	./brew install icoutils
fi

# create path for ghostscript
gs_ver="$(./gs --version)"
export GS_OPTIONS="-sICCProfilesDir=$install_dir/Contents/Resources/usr/opt/ghostscript/share/ghostscript/$gs_ver/iccprofiles/ -sGenericResourceDir=$install_dir/Contents/Resources/usr/opt/ghostscript/share/ghostscript/$gs_ver/Resource/ -sFontResourceDir=$install_dir/Contents/Resources/usr/opt/ghostscript/share/ghostscript/$gs_ver/Resource/Font"

# get newest octave formula and then build octave
curl https://raw.githubusercontent.com/schoeps/homebrew-science/octave/octave.rb -o "$install_dir/Contents/Resources/usr/Library/Taps/homebrew/homebrew-science/octave.rb"
octave_settings="--build-from-source --without-java --universal --with-audio --with-openblas --without-fltk --verbose --debug"
if [ "$build_devel" == "y" ]; then
	octave_settings="$octave_settings --devel"
fi
if [ "$build_gui" == "y" ]; then
	octave_settings="$octave_settings --with-gui"
fi

# finally build octave
./brew install octave $octave_settings

# get versions
oct_ver="$(./octave --version |sed -n 1p |grep -o '\d\..*$' )"
oct_ver_string="$(./octave --version | sed -n 1p)"
oct_copy="$(./octave --version | sed -n 2p | cut -c 15- )"

# rebuilding fontconfig from source seems to fix gnuplot font problems
./brew uninstall fontconfig
./brew install fontconfig --build-from-source

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
echo '  return "export PATH=\"'$install_dir'/Contents/Resources/usr/bin/:$PATH;\";"' >> $tmp_script
echo 'end export_path'  >> $tmp_script
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
echo '  set cmd to export_gs_options() & export_gnuterm() & export_path() & run_octave_open(filename)' >> $tmp_script
echo '  do shell script cmd' >> $tmp_script
echo 'end open'  >> $tmp_script
echo '' >> $tmp_script
echo 'on run' >> $tmp_script
echo '  path_check()' >> $tmp_script
if [ "$build_gui" == "y" ]; then
	echo '  set cmd to export_gs_options() & export_gnuterm() & export_path() & run_octave_gui()' >> $tmp_script
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

# create or update entries in the application's plist
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
echo "" > "$install_dir/Contents/Resources/DEPENDENCIES"
for f in $(./brew deps octave)
do
	./brew info $f | sed -e 's$homebrew/science/$$g'| sed -e 's$: .*$$g' | sed -e 's$/Applications.*$$g' | head -n3 >> "$install_dir/Contents/Resources/DEPENDENCIES"
	echo "" >> "$install_dir/Contents/Resources/DEPENDENCIES"
done

# create a nice dmg disc image with create-dmg (MIT License)
if [ "$build_dmg" == "y" ]; then
	# get make-dmg from github
	tmp_dir=$(mktemp -d /tmp/octave-XXXX)
	git clone https://github.com/schoeps/create-dmg.git $tmp_dir/create-dmg

	# get background image
	curl https://raw.githubusercontent.com/schoeps/octave_installer/master/background.tiff -o "$tmp_dir/background.tiff"

	# running create-dmg; this may issue warnings if run headless. However, the dmg
	# will still be created, only some beautifcation cannot be applied
	cd "$tmp_dir/create-dmg"
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
	--disk-image-size 1400 \
	--background "$tmp_dir/background.tiff" \
	"$dmg_dir/Octave-Installer.dmg" \
	"$install_dir" 

	echo DMG ready: $dmg_dir/Octave-Installer.dmg
fi