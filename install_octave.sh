#!/usr/bin/env bash

install_dir="/Applications/Octave.app"
build_gui=y
build_devel=n
build_dmg=y
use_experimental=n
make_fail=n
use_gcc=n
use_java=n
use_openblas=n
dmg_dir="$HOME"
verbose=n
with_test=y

function usage()

{
	echo " $(basename $0)"
	echo " $(basename $0) [OPTION] ..."
	echo " $(basename $0) [OPTION ARG] ..."
	echo ""
	echo " Build an Octave application bundle for Mac OS X."
	echo ""
	echo " Several options are supported;"
	echo ""
	echo "  -a, --dmg-dir DIR"
	echo "    Location to create dmg [$dmg_dir]."
	echo "  -b, --build-dmg"
	echo "    Build a dmg."
	echo "  -c, --cli-only"
	echo "    Do not build the gui."
	echo "  -d, --build-devel"
	echo "    Build the latest development snapshot."
	echo "  -e, --error"
	echo "    Exit on error."
	echo "  -f, --make-fail"
	echo "    make homebrew fail to get a shell with proper environment."
	echo "  -g, --use-gcc"
	echo "    Compile with gcc instead of clang."
	echo "  -j, --use-java"
	echo "    Compile with java."
	echo "  -o, --use-openblas"
	echo "    Compile with openlas instead of Apple's blas."
	echo "  -h, -?, --help"
	echo "    Display this help text."
	echo "  -i, --install-dir DIR"
	echo "    Specify the directory where Octave will be installed [$install_dir]."
	echo "  -t, --without-test"
	echo "    Do not run 'make check'."
	echo "  -v, --verbose"
	echo "    Tell user the state of all options."
	echo "  -x, --experimental"
	echo "    Use experimental formula."
	echo ""
}

while [[ $1 != "" ]]; do
  case "$1" in
    -a|--dmg-dir) if [ $# -gt 1 ]; then
          dmg_dir=$2; shift 2
        else 
          echo "$1 requires an argument" >&2
          exit 1
        fi ;;
    -b|--build-dmg) build_dmg=y; shift 1;;
    -c|--cli-only) build_gui=n; shift 1;;
    -d|--build-devel) build_devel=y; shift 1;;
    -e|--error) set -e; shift 1;;
    -f|--make-fail) make_fail=y; shift 1;;
    -g|--use-gcc) use_gcc=y; shift 1;;
    -j|--use-java) use_java=y; shift 1;;
    -o|--use-openblas) use_openblas=y; shift 1;;
    -h|--help|-\?) usage; exit 0;;
    -i|--install-dir) if [ $# -gt 1 ]; then
          install_dir=$2; shift 2
        else 
          echo "$1 requires an argument" >&2
          exit 1
        fi ;;
    -t|--without-test) with_test=n; shift 1;;
    -v|--verbose) verbose=y; shift 1;;
    -x|--experimental) use_experimental=y; shift 1;;
    --) shift; break;;
    *) echo "invalid option: $1" >&2; usage; exit 1;;
  esac
done

if [ "$verbose" == "y" ]; then
	echo install_dir = \"$install_dir\"
	echo build_gui = \"$build_gui\"
	echo build_devel = \"$build_devel\"
	echo build_dmg = \"$build_gui\"
	echo dmg_dir = \"$dmg_dir\"
	echo make_fail = \"$make_fail\"
	echo use_gcc = \"$use_gcc\"
	echo use_java = \"$use_java\"
	echo use_openblas = \"$use_openblas\"
	echo with_test = \"$with_test\"
	set -v
fi

# set some environment variables
# export HOMEBREW_BUILD_FROM_SOURCE=1
export HOMEBREW_OPTFLAGS="-march=core2"
PATH="$install_dir/Contents/Resources/usr/bin/:$PATH"

# check if we do full or update
if [ -e "$install_dir/Contents/Resources/usr/bin/brew" ]; then
	echo "Update."
	install_type='update'
else
	install_type='full'
fi

if [ "$install_type" == "update" ]; then
	# uninstall octave and linear algebra
	echo "Update homebrew installation in $install_dir."
	cd "$install_dir/Contents/Resources/usr/bin"
	if [ -d "$install_dir/Contents/Resources/usr/Cellar/arpack" ]; then
		./brew uninstall arpack
	fi
	if [ -d "$install_dir/Contents/Resources/usr/Cellar/qrupdate" ]; then
		./brew uninstall qrupdate
	fi
	if [ -d "$install_dir/Contents/Resources/usr/Cellar/suite-sparse" ]; then
		./brew uninstall suite-sparse
	fi
	if [ -d "$install_dir/Contents/Resources/usr/Cellar/octave" ]; then
		./brew uninstall octave
	fi
else
	# install homebrew
	echo "Create new homebrew installation in $install_dir."
	osacompile -o "$install_dir" -e " "
	mkdir -p "$install_dir/Contents/Resources/usr"
	curl -L https://github.com/Homebrew/homebrew/tarball/master | tar xz --strip 1 -C "$install_dir/Contents/Resources/usr"
	cd "$install_dir/Contents/Resources/usr/bin"
fi

./brew update # get new formulas
./brew upgrade # compile new formulas
./brew cleanup # remove old versions

# be conservative regarding architectures
# use Mac's (BSD) sed
/usr/bin/sed -i '' 's/march=native/march=core2/g' "$install_dir/Contents/Resources/usr/Library/Homebrew/extend/ENV/super.rb" 
/usr/bin/sed -i '' 's/march=native/march=core2/g' "$install_dir/Contents/Resources/usr/Library/Homebrew/extend/ENV/std.rb" 

# go to the bin directory 
cd "$install_dir/Contents/Resources/usr/bin"

# install trash command line utility
./brew install trash --universal

# install gcc and set FC
./brew install gcc --universal
export FC="$install_dir/Contents/Resources/usr/bin/gfortran"

# get scietific libraries
./brew tap homebrew/science

# enforce fltk (without fltk all native graphics is disabled and
# e.g. gl2ps is not used. This will be untangled in Octave 4.2)
# we use devel because fltk 1.3.3 does not work on recent Mac OS
./brew install fltk --universal --devel

# create path for ghostscript
./brew install ghostscript  --universal
gs_ver="$(./gs --version)"
export GS_OPTIONS="-sICCProfilesDir=$install_dir/Contents/Resources/usr/opt/ghostscript/share/ghostscript/$gs_ver/iccprofiles/ -sGenericResourceDir=$install_dir/Contents/Resources/usr/opt/ghostscript/share/ghostscript/$gs_ver/Resource/ -sFontResourceDir=$install_dir/Contents/Resources/usr/opt/ghostscript/share/ghostscript/$gs_ver/Resource/Font"

# install gnuplot 5.1 (HEAD)
gnuplot_settings="--universal --with-cairo --universal --HEAD"
if [ "$build_gui" == "y" ]; then
	gnuplot_settings="$octave_settings --with-qt5"	
fi
if [ -d "/Library/Frameworks/AquaTerm.framework" ]; then
	gnuplot_settings="$gnuplot_settings --with-aquaterm"
else
	echo "Did not find Aquaterm; build gnuplot without it."
fi
./brew install gnuplot $gnuplot_settings

# icoutils
./brew install icoutils --universal

# use gcc for all scientific libraries
if [ "$use_gcc" == "y" ]; then
	export HOMEBREW_CC=gcc-6
	export HOMEBREW_CXX=g++-6
fi

# install graphicsmagick and ensure quantum-depth-16
./brew install graphicsmagick --universal --with-quantum-depth-16

# install Qscintilla2 without python bindings
./brew install qscintilla2 --universal --without-python --without-plugin --verbose

# we prefer openblas over Apple's BLAS implementation
blas_settings="--universal"
if [ "$use_openblas" == "y" ]; then
	blas_settings="$blas_settings --with-openblas"
fi
./brew install arpack $blas_settings
./brew install qrupdate $blas_settings
./brew install suite-sparse $blas_settings

# get newest octave formula
if [ "$use_experimental" == "y" ]; then
	curl https://raw.githubusercontent.com/schoeps/homebrew-science/octave/octave.rb -o "$install_dir/Contents/Resources/usr/Library/Taps/homebrew/homebrew-science/octave.rb"
fi
	
# build octave
octave_settings="--universal --without-docs --build-from-source --without-java --universal --with-audio --without-fltk --debug $blas_settings"
if [ "$verbose" == "y" ]; then
	octave_settings="$octave_settings --verbose"
fi
if [ "$build_devel" == "y" ]; then
	octave_settings="$octave_settings --HEAD"
fi
if [ "$build_gui" == "n" ]; then
	octave_settings="$octave_settings --without-qt5"
else
	octave_settings="$octave_settings --with-qt5"	
fi
if [ "$use_java" == "y" ]; then
	octave_settings="$octave_settings --with-java"
fi
if [ "$with_test" == "n" ]; then
	octave_settings="$octave_settings --without-test"
fi
if [ "$make_fail" == "y" ]; then
	# enforce failure 
	/usr/bin/sed -i '' 's/\".\/bootstrap" if build.head?/\"false\"/g' "$install_dir/Contents/Resources/usr/Library/Taps/homebrew/homebrew-science/octave.rb"
fi

# finally build octave
./brew install octave $octave_settings

# get versions
oct_ver="$(./octave --version | /usr/bin/sed -n 1p | /usr/bin/grep -o '\d\..*$' )"
oct_ver_string="$(./octave --version | /usr/bin/sed -n 1p)"
oct_copy="$(./octave --version | /usr/bin/sed -n 2p | /usr/bin/cut -c 15- )"

# use local font cache instead of global one
/usr/bin/sed -i '' 's/\/Applications.*fontconfig/~\/.cache\/fontconfig/g' "$install_dir/Contents/Resources/usr/etc/fonts/fonts.conf" 

# remove unnecessary files installed due to wrong dependency management
if [ -d "$install_dir/Contents/Resources/usr/Cellar/pyqt" ]; then
	./brew uninstall pyqt
fi

# we do not need veclibfort if using openblas
if [ "$use_openblas" == "y" && [ -d "$install_dir/Contents/Resources/usr/Cellar/veclibfort" ]; then
	./brew uninstall veclibfort
fi

# tidy up: make a symlink to system "/var
rm -R "$install_dir/Contents/Resources/usr/var"
ln -s "/var" "$install_dir/Contents/Resources/usr/var"

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
echo 'on cache_fontconfig()' >> $tmp_script
echo '  set fileTarget to (path to home folder as text) & ".cache:fontconfig"' >> $tmp_script
echo '  try' >> $tmp_script
echo '    fileTarget as alias' >> $tmp_script
echo '  on error' >> $tmp_script
echo '    display dialog "Font cache not found, so first plotting will be slow. Create font cache now?" with icon caution buttons {"Yes", "No"}' >> $tmp_script
echo '    if button returned of result = "Yes" then' >> $tmp_script
echo '      do shell script "'$install_dir'/Contents/Resources/usr/bin/fc-cache -frv;"' >> $tmp_script
echo '    end if' >> $tmp_script
echo '  end try' >> $tmp_script
echo 'end cache_fontconfig' >> $tmp_script
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
echo '  path_check()' >> $tmp_script
echo '  cache_fontconfig()' >> $tmp_script
echo '  set filename to "\"" & POSIX path of item 1 of argv & "\""' >> $tmp_script
echo '    set cmd to export_gs_options() & export_gnuterm() & export_path() & export_dyld() & run_octave_open(filename)' >> $tmp_script
echo '    do shell script cmd' >> $tmp_script
echo 'end open'  >> $tmp_script
echo '' >> $tmp_script
echo 'on run' >> $tmp_script
echo '  path_check()' >> $tmp_script
echo '  cache_fontconfig()' >> $tmp_script
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
	/usr/bin/python "$python_script" "$install_dir/Contents/Resources/applet.icns" $install_dir/Contents/Resources/usr/Cellar/octave/*/libexec/octave/*/exec/*/octave-gui
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
	--disk-image-size 2000 \
	--background "$tmp_dir/background.tiff" \
	"$dmg_dir/Octave-Installer.dmg" \
	"$install_dir" 

	echo DMG ready: $dmg_dir/Octave-Installer.dmg
fi
