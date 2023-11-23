# Kiwix for Apple iOS & macOS

This is the home for Kiwix apps for Apple iOS and macOS.

[![CodeFactor](https://www.codefactor.io/repository/github/kiwix/apple/badge)](https://www.codefactor.io/repository/github/kiwix/apple)
[![CI Build Status](https://github.com/kiwix/apple/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/kiwix/apple/actions/workflows/ci.yml?query=branch%3Amain)
[![CD Build Status](https://github.com/kiwix/apple/actions/workflows/cd.yml/badge.svg?branch=main)](https://github.com/kiwix/apple/actions/workflows/cd?query=branch%3Amain)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
<img src="https://img.shields.io/badge/Swift-5.2-orange.svg" alt="Drawing="/>

## Download

Kiwix apps are made available primarily via the [App Store](https://ios.kiwix.org) and [Mac App Store](https://macos.kiwix.org). macOS version can also be [downloaded directly](https://download.kiwix.org/release/kiwix-desktop-macos/kiwix-desktop-macos.dmg).

Most recent versions of Kiwix support the three latest major versions of the
OSes (either iOS or macOS). Older versions of Kiwix being still
downloadable for older versions of macOS and iOS on the Mac App Store.

## Develop

Kiwix developers usually work with latest macOS and Xcode. Check our [Continuous Integration Workflow](https://github.com/kiwix/apple/blob/main/.github/workflows/ci.yml) to find out which XCode version we use on Github Actions.

### CPU Architectures

Kiwix compiles on both macOS architectures x86_64 and arm64 (Apple silicon).

Kiwix for iOS and macOS can run, in both cases, on x86_64 or arm64.

### Dependencies

To compile Kiwix you rely on the following compilation tools:

* An [Apple Developer account](https://developer.apple.com) (doesn't require membership)
* Latest Apple Developers Tools ([Xcode](https://developer.apple.com/xcode/))
* Its command-line utilities (`xcode-select --install`)
* `CoreKiwix.xcframework` ([libkiwix](https://github.com/kiwix/libkiwix) and [libzim](https://github.com/openzim/libzim))

### Steps

To compile Kiwix, follow these steps:

* Put `CoreKiwix/xcframework` at the root of this folder
* Open project with Xcode `open Kiwix.xcodeproj/project.xcworkspace/`
* Change the Bundle Identifier (in *Signing & Capabilities*)
* Select appropriate Signing Certificate/Profile.

### Getting `CoreKiwix.xcframework`

`CoreKiwix.xcframework` is published with all supported platforms and CPU architectures:

- [latest release](https://download.kiwix.org/release/libkiwix/libkiwix_xcframework.tar.gz)
- [latest nightly](https://download.kiwix.org/nightly/libkiwix_xcframework.tar.gz): using `main` branch of both `libkiwix` and `libzim`.

#### Compiling `CoreKiwix.xcframework`

You may want to compile it yourself, to use different branches of said projects for instance.

The xcframework is a bundle of all libkiwix dependencies for multiple architectures
and platforms. The `CoreKiwix.xcframework` will contain libkiwix
library for macOS archs and for iOS. It is built off [kiwix-build
repo](https://github.com/kiwix/kiwix-build).

Make sure to preinstall kiwix-build prerequisites (ninja and meson). If you use homebrew, run the following

```sh
brew install ninja meson
```

Make sure Xcode command tools are installed. Make sure to download an
iOS SDK if you want to build for iOS.

```sh
xcode-select --install
```

Then you can build `libkiwix` 

```sh
git clone https://github.com/kiwix/kiwix-build.git
cd kiwix-build
python3 -m venv .venv
source .venv/bin/activate
pip install -e .

kiwix-build --target-platform apple_all_static libkiwix
# assuming your kiwix-build and apple folder at at same level
cp -r BUILD_apple_all_static/INSTALL/lib/CoreKiwix.xcframework ../apple/
```

You can now launch the build from Xcode and use the iOS simulator or
your macOS target. At this point the xcframework is not signed.

## License

[GPLv3](https://www.gnu.org/licenses/gpl-3.0) or later, see
[LICENSE](LICENSE) for more details.