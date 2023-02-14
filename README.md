# Kiwix for iOS & macOS

This is the home for Kiwix apps on iOS and macOS.

[![CodeFactor](https://www.codefactor.io/repository/github/kiwix/apple/badge)](https://www.codefactor.io/repository/github/kiwix/apple)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
<img src="https://img.shields.io/badge/Swift-5.2-orange.svg" alt="Drawing="/>

### Mobile app for iPads & iPhones ###
- Download the iOS mobile app on the [App Store](https://ios.kiwix.org)

### Kiwix Desktop for macOS ###
- Download Kiwix Desktop on the [Mac App Store](https://macos.kiwix.org)
- Download Kiwix Desktop [DMG file](https://download.kiwix.org/release/kiwix-desktop-macos/kiwix-desktop-macos.dmg)

## Developers

### Dependencies

* An [Apple Developer account](https://developer.apple.com) (doesn't require membership)
* Latest Apple Developers Tools ([Xcode](https://developer.apple.com/xcode/))
* Its command-line utilities (`xcode-select --install`)
* `libkiwix.xcframework` ([libkiwix](https://github.com/kiwix/libkiwix))

### Creating `libkiwix.xcframework`

Instructions to build libkiwix at [on the kiwix-build repo](https://github.com/kiwix/kiwix-build).

The xcframework is a bundle of a library for multiple architectures and/or platforms. The `libkiwix.xcframework` will contain libkiwix library for macOS arch and for iOS. You don't have to follow steps for other platform/arch if you don't need them.

Following steps are done from kiwix-build root and assume your apple repository is at `../apple`.

#### Build libkiwix

Make sure to preinstall kiwix-build prerequisites (ninja and meson).

If you use homebrew, run the following

```bash
brew install ninja meson
```

Make sure xcode command tools are installed

```bash
xcode-select --install
```

After you can build the `libkiwix` 

```bash
git clone https://github.com/kiwix/kiwix-build.git
cd kiwix-build
# [iOS] build libkiwix
kiwix-build --target-platform iOS_multi libkiwix
# [macOS] build libkiwix
kiwix-build --target-platform macOS_arm64 libkiwix
kiwix-build --target-platform macOS_x86_64 libkiwix
```

#### Create fat archive with all dependencies

This creates a single `.a` archive named libkiwix which contains all libkiwix's dependencies.
If you are to create an xcframework with multiple architectures/platforms, repeat this step for each:

* `macOS_x86_64`
* `macOS_arm64`
* `iOS_x86_64`
* `iOS_arm64`

You'll have to do it for both iOS archs although you built it using `multi`.

```bash
libtool -static -o BUILD_<target>/INSTALL/lib/libkiwix.a BUILD_<target>/INSTALL/lib/*.a
```

#### Add fat archive to xcframework

```bash
xcodebuild -create-xcframework -library BUILD_<target>/INSTALL/lib/libkiwix.a -headers BUILD_<target>/INSTALL/include -output ../apple/Libraries/libkiwix.xcframework
```

You can now launch the build from Xcode and use the iOS simulator or your macOS target.


### Building Kiwix iOS or Kiwix macOS

* Open project with Xcode `open Kiwix.xcodeproj`
* Change the App groups (in *Capabilities*) and Bundle Identifier for both iOS and Bookmarks targets
  * App Group must be different and unique (ex: `tld.mydomain.apple`)
  * iOS Bundle Identifier must be different and unique (ex: `tld.mydomain.apple.Kiwix`)
  * Bookmarks Bundle Identifier must be a child of iOS one (ex: `tld.mydomain.apple.Kiwix.Bookmarks`)
  * ⚠ if you are using a regular (non-paying) Apple Developer Account, you are limited in the number of App IDs you can use so be careful not to fumble much with those.
* Change the Signing profile to your account.
