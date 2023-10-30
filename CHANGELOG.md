# Changelog

All notable new changes to this project will be documented in this file. (Hopefully.)

This changelog file was added late in the project's history, in 2023-10, and there are years of project history before that which are not captured here.

## [Unreleased] - in progress

## [???] - in progress as of 2023-10-25

### Changed

- Add support for macOS 12 and newer.
- Remove support for macOS 10.15 and older.
- Add support for Apple Silicon ("AS").
  - Support Homebrew's new file layout on AS.
- Change app and DMG naming conventions.
  - Include build suffix in app name (with option to turn that off).
  - Use "_" instead of "-" to separate version and build suffix.
- Include subversion in Octave.app build, because it is now needed for downloading netpbm.
- Remove create-dmg Git submodule and reference it as an external program, to support SSH GitHub access, and because I dislike Git submodules.
- Code refactoring.

## [10acffb2e94c7636ffb31f74818287c68fb0460b] - 2020-10-24

This was the last commit before I started keeping a [changelog](https://keepachangelog.com/). We did not do releases or version numbers at this point; you just used whatever was on the main branch in the repo.

### Fixed

- Add help text about using `-u`` for beta builds.

## [eb6ba6782407c1d9007d0b686f671ab76e624ff0] - 2021-08-18

### Changed

- Bump default to Octave 6.3.0.

## [70a001a1ed585eb074e535c9232b93175c7f5062] - 2020-12-22

### Changed

- Bump default to Octave 6.1.0 from 5.2.0.
