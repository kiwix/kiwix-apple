fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios devbuild

```sh
[bundle exec] fastlane ios devbuild
```

Build iOS app without codesigning

### ios build

```sh
[bundle exec] fastlane ios build
```

Build iOS app for AppStore

### ios switch_manual

```sh
[bundle exec] fastlane ios switch_manual
```



### ios build_manual

```sh
[bundle exec] fastlane ios build_manual
```

Build iOS app for AppStore, manual signing

----


## Mac

### mac devbuild

```sh
[bundle exec] fastlane mac devbuild
```

Build macOS app without codesigning

### mac build

```sh
[bundle exec] fastlane mac build
```

Build macOS app for AppStore

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
