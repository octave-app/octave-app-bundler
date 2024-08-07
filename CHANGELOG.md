# octave-app-bundler CHANGELOG

This is the changelog for [octave-app-bundler](https://github.com/octave-app/octave-app-bundler), the tools used to create [Octave.app](https://github.com/octave-app/octave-app).

This file has info about the developer-facing changes in `bundle_octapp` and the other build tools used to create Octave.app. It doesn't include info about user-facing changes in Octave.app itself; see the [octave-app repo's](https://github.com/octave-app/octave-app) CHANGELOG.md for that.

This changelog file was added late in the project's history, in 2023, and there are years of project history before that which are not captured here.

## [0.2.0] - in progress as of 2023-10 through 2024-07 and later

Started numbering versions here, as part of the Octave.app 8.x and 9.x release process. Reserving "0.1.*" version numbers for retroactively tagging older commits.

### Changed

- Add support for macOS 12 and newer.
- Remove support for macOS 10.15 and older.
- Add support for Apple Silicon ("AS").
  - Support Homebrew's new file layout on AS.
- Change app and DMG naming conventions.
  - Include build suffix in app name, by default.
  - Use "_" instead of "-" to separate version and build suffix.
- Remove create-dmg Git submodule and reference it as an external program
  - To support GitHub access via SSH, and because I dislike Git submodules.
- Expose original `ver` as `octapp.ver_pristine`.
- Create an `+octapp` namespace, and move `octave_app_diagnostic_dump` to `octapp.diagnostic_dump`.
- Update `octapp.diagnostic_dump`.
  - Convert to GNU Octave code style.
  - Support alternate default system Homebrew on AS.
- Rearrange octapp metadata.
  - Put octapp metadata under `Contents/Resources/octapp-meta` instead of directly under the app bundle root.
    - (For organization, and in the vain hope that this might fix codesigning.)
  - Capture more brew metadata (config, formula versions) to additional files.
- Add `octapp_helper` tool.

### Internal

- Big refactoring for nicer, cleaner Bash code.

## [10acffb2e94c7636ffb31f74818287c68fb0460b] - 2020-10-24

This was the last commit before I started keeping a [changelog](https://keepachangelog.com/). We did not do releases or version numbers at this point; you just used whatever was on the main branch in the repo.

### Fixed

- Add help text about using `-u` for beta builds.

## [eb6ba6782407c1d9007d0b686f671ab76e624ff0] - 2021-08-18

### Changed

- Bump default to Octave 6.3.0.

## [70a001a1ed585eb074e535c9232b93175c7f5062] - 2020-12-22

### Changed

- Bump default to Octave 6.1.0 from 5.2.0.
