# Kiwix for Apple iOS & macOS

This is the home for Kiwix apps for Apple iOS and macOS.

[![CodeFactor](https://www.codefactor.io/repository/github/kiwix/apple/badge)](https://www.codefactor.io/repository/github/kiwix/apple)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
<img src="https://img.shields.io/badge/Swift-5.2-orange.svg" alt="Drawing="/>

## Download

Kiwix apps are made available primarily via the [Mac App
Store](https://macos.kiwix.org).

Most recent versions of Kiwix support the three latest versions of the
OSes (either iOS or macOS). Older versions of Kiwix being still
downloadable for older versions of macOS and iOS on the Mac App Store.

### iPads & iPhones ###
- Download the iOS mobile app on the [App Store](https://ios.kiwix.org)

### macOS ###
- Download Kiwix Desktop on the [Mac App Store](https://macos.kiwix.org)
- Download Kiwix Desktop [DMG file](https://download.kiwix.org/release/kiwix-desktop-macos/kiwix-desktop-macos.dmg)

## Develop

Kiwix developers use to work with cutting-edge versions of both macOS
and Xcode. [Continuous
integration](https://en.wikipedia.org/wiki/Continuous_integration)
secures that the whole project still compiles on the next to last
version of macOS with latest version of Xcode distributed on it.

### CPU Architectures

Kiwix compiles on both macOS with x86_64 or arm64 (M1, M2, ... family).

Kiwix for iOS and macOS can run, in both cases, on x86_64 or arm64.

### Dependencies

To compile Kiwix you rely on the following compilation tools:
* An [Apple Developer account](https://developer.apple.com) (doesn't require membership)
* Latest Apple Developers Tools ([Xcode](https://developer.apple.com/xcode/))
* Its command-line utilities (`xcode-select --install`)
* `CoreKiwix.xcframework` ([libkiwix](https://github.com/kiwix/libkiwix) and [libzim](https://github.com/openzim/libzim))

### Steps

To compile Kiwix, follow these steps:
* Open project with Xcode `open Kiwix.xcodeproj/project.xcworkspace/`
* Change the Bundle Identifier (in *Signing & Capabilities*)
* Select appropriate Signing Certificate/Profile.

## Compile `CoreKiwix.xcframework` yourself

`CoreKiwix.xcframework` is [made
available](https://dev.kiwix.org/apple/CoreKiwix.xcframework.zip) for
all supported OSes and CPU architectures. But you might want to
compile this piece (C++ code) by yourself. Here follow the
instructions to build libkiwix at [on the kiwix-build
repo](https://github.com/kiwix/kiwix-build).

The xcframework is a bundle of a library for multiple architectures
and/or platforms. The `CoreKiwix.xcframework` will contain libkiwix
library for macOS archs and for iOS. You don't have to follow steps
for other platform/arch if you don't need them.

Following steps are done from kiwix-build root and assume your apple
repository is at `../apple`.

### Build libkiwix

Make sure to preinstall kiwix-build prerequisites (ninja and meson).

If you use homebrew, run the following

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
# [iOS] build libkiwix
kiwix-build --target-platform iOS_arm64 libkiwix
kiwix-build --target-platform iOS_x86_64 libkiwix  # iOS simulator in Xcode
# [macOS] build libkiwix
kiwix-build --target-platform macOS_x86_64 libkiwix
kiwix-build --target-platform macOS_arm64_static libkiwix
```

### Create fat archive with all dependencies

This creates a single `.a` archive named `merged.a` (for each
platform) which contains libkiwix and all it's dependencies.  Skip
those you don't want to support.

```sh
libtool -static -o BUILD_macOS_x86_64/INSTALL/lib/merged.a BUILD_macOS_x86_64/INSTALL/lib/*.a
libtool -static -o BUILD_macOS_arm64_static/INSTALL/lib/merged.a BUILD_macOS_arm64_static/INSTALL/lib/*.a
libtool -static -o BUILD_iOS_x86_64/INSTALL/lib/merged.a BUILD_iOS_x86_64/INSTALL/lib/*.a
libtool -static -o BUILD_iOS_arm64/INSTALL/lib/merged.a BUILD_iOS_arm64/INSTALL/lib/*.a
```

If you built macOS support for both archs (that's what you want unless
you know what you're doing), you need to merge both files into a
single one

```sh
mkdir -p macOS_fat
lipo -create -output macOS_fat/merged.a \
	-arch x86_64 BUILD_macOS_x86_64/INSTALL/lib/merged.a \
	-arch arm64 BUILD_macOS_arm64_static/INSTALL/lib/merged.a
```

### Add fat archive to xcframework

```sh
xcodebuild -create-xcframework \
	-library macOS_fat/merged.a -headers BUILD_macOS_x86_64/INSTALL/include \
	-library BUILD_iOS_x86_64/INSTALL/lib/merged.a -headers BUILD_iOS_x86_64/INSTALL/include \
	-library BUILD_iOS_arm64/INSTALL/lib/merged.a -headers BUILD_iOS_arm64/INSTALL/include \
	-output ../apple/CoreKiwix.xcframework
```

You can now launch the build from Xcode and use the iOS simulator or
your macOS target. At this point the xcframework is not signed.

## License

[GPLv3](https://www.gnu.org/licenses/gpl-3.0) or later, see
[LICENSE](LICENSE) for more details.