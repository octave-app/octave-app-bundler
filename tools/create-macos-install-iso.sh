#!/usr/bin/env bash
#
# create-macos-install-iso.sh - Create a macOS installer ISO from the installer app.
#
# I use this to create an ISO that VMware Fusion can use to create a macOS 12, 13, or 14
# VM. It doesn't seem to be able to directly use the Install macOS Monterey.app installer.
#
# For this to work, you must download the macOS installer of the right version from the
# Mac App Store so it's in your /Applications folder. Download links:
#
# * Info: https://support.apple.com/en-us/102662
# * maOS 12 Monterey
#   * macappstores://apps.apple.com/app/macos-monterey/id1576738294?mt=12
# * macOS 13 Ventura
#   * macappstores://apps.apple.com/app/macos-ventura/id1638787999?mt=12
# * macOS 14 Sonoma
#   * macappstores://apps.apple.com/app/macos-sonoma/id6450717509?mt=12
#
# I ganked this from https://gist.github.com/memoryleak/30f275beebe28595d736eb2b380a0fa9 on 2024-01-12.
# Tested on a macOS 14 Intel host running VMware Fusion 13.5.0.

# TODO: Detect exact version of the installer (like 12.7.5) and include it in the ISO file name.
# TODO: Is the created CD architecture-specific? If so, add an "Intel" suffix.

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

# Utility functions

THIS_PROGRAM=$(basename $0)
THIS_DIR=$(realpath $(dirname $0))

function info() {
  echo >&2 "$*"
}

function error() {
  echo >&2 "${THIS_PROGRAM}: ERROR: $*"
}

function die() {
  local msg="$1"
  error "$msg"
  exit 1
}

function verbose() {
  if [[ $VERBOSE == 'y' ]]; then
    echo >&2 "$*"
  fi
}

function is_dry_run() {
  if [[ $DRY_RUN == 'y' ]]; then
    return 0
  else
    return 1
  fi
}

function wet() {
  if is_dry_run; then
    info "dry run: would run: $*"
  else
    verbose "running: $*"
    "$@"
    return $?
  fi
}

function timeit() {
  local t0=$(tic)
  "$@"
  toc "action" "$t0"
}

function tic() {
  date +%s
}

function toc() {
  local label start_time end_time elapsed_s elapsed_m
  label="$1"
  start_time="$2"
  end_time=$(date +%s)
  elapsed_s=$((end_time - start_time))
  elapsed_m=$((elapsed_s / 60))
  elapsed_s=$((elapsed_s - (elapsed_m * 60)))
  info $(printf "elapsed time: %s: %02d:%02d" "$label" "$elapsed_m" "$elapsed_s")
}


# Script-specific stuff

# 'monterey', 'ventura', or 'sonoma'
WHICH_OS_VER='monterey'
VERBOSE=n
DRY_RUN=

function parse_cli_args() {
  local arg

  REMAINDER_ARGS=()
  while [[ $# -ge 1 ]]; do
    arg="$1"; shift
    case "$arg" in
      -m | --major)
        WHICH_OS_VER="$1"; shift ;;
      -v | --verbose)
        VERBOSE=y ;;
      -Y | --dry-run)
        DRY_RUN=y ;;
      *)
        die "invalid option: ${arg}. See ${THIS_PROGRAM} --help for help." ;;
    esac
  done
}

parse_cli_args "$@"

# These sizes are based on trial and error on Apple Silicon.
if [[ "$WHICH_OS_VER" = "monterey" ]]; then
  OS_NAME="Monterey"
  OS_MAJ_VER="12"
  VOL_SIZE="14g"
elif [[ "$WHICH_OS_VER" = "ventura" ]]; then
  OS_NAME="Ventura"
  OS_MAJ_VER="13"
  VOL_SIZE="14g"
elif [[ "$WHICH_OS_VER" = "sonoma" ]]; then
  OS_NAME="Sonoma"
  OS_MAJ_VER="14"
  VOL_SIZE="15g"
else
  die "Unsupported OS version: ${WHICH_OS_VER}"
fi
NAME="Install macOS ${OS_MAJ_VER} ${OS_NAME}"
NAME2="Install macOS ${OS_NAME}"

# ISO creation logic

t0_all=$(tic)

INSTALLER_APP="/Applications/${NAME2}.app"
ISO_FILE="${HOME}/Downloads/${NAME}.iso"

if ! [[ -d "$INSTALLER_APP" ]]; then
  die "Installer app file not found: ${INSTALLER_APP}"
fi

wet sudo hdiutil create -o "/tmp/$NAME" -size "$VOL_SIZE" -volname "$NAME" -layout SPUD -fs HFS+J
wet sudo hdiutil attach "/tmp/${NAME}.dmg" -noverify -mountpoint "/Volumes/$NAME"
wet sudo "${INSTALLER_APP}/Contents/Resources/createinstallmedia" --volume "/Volumes/$NAME" --nointeraction
wet hdiutil eject -force "/Volumes/${NAME2}"
wet hdiutil convert "/tmp/${NAME}.dmg" -format UDTO -o "$HOME/Downloads/$NAME"
wet sudo rm -fv "/tmp/${NAME}.dmg"
wet mv -v "$HOME/Downloads/${NAME}.cdr" "$ISO_FILE"

toc 'ISO creation' "$t0_all"
info "Created ISO at: ${ISO_FILE}"
