# Kiwix for iOS & macOS

This is the home for Kiwix apps on iOS and macOS.

[![CodeFactor](https://www.codefactor.io/repository/github/kiwix/apple/badge)](https://www.codefactor.io/repository/github/kiwix/apple)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
<img src="https://img.shields.io/badge/Swift-5.2-orange.svg" alt="Drawing="/>

### Mobile app for iPads & iPhones ###
- Download the iOS mobile app on [iTunes App Store](https://ios.kiwix.org)

### Kiwix Desktop for macOS ###
- Download Kiwix Desktop on [iTunes App Store](https://macos.kiwix.org)
- Download Kiwix Desktop [DMG file](https://download.kiwix.org/release/kiwix-desktop-macos/)

## Developers

### Dependencies

* An [Apple Developer account](https://developer.apple.com) (doesn't require membership)
* Latest Apple Developers Tools ([Xcode](https://developer.apple.com/xcode/))
* Its command-line utilities (`xcode-select --install`)
* `libkiwix.xcframework` ([kiwix-lib](https://github.com/kiwix/kiwix-lib))

### Creating `libkiwix.xcframework`

Instructions to build kiwix-lib at [on the kiwix-build repo](https://github.com/kiwix/kiwix-build).

The xcframework is a bundle of a library for multiple architectures and/or platforms. The `libkiwix.xcframework` will contain libkiwix library for macOS arch and for iOS. You don't have to follow steps for other platform/arch if you don't need them.

Following steps are done from kiwix-build root and assume your apple repository is at `../apple`.

#### Build kiwix-lib
```bash
git clone https://github.com/kiwix/kiwix-build.git
cd kiwix-build
# if on macOS mojave (10.14), install headers to standard location
# https://developer.apple.com/documentation/xcode_release_notes/xcode_10_release_notes?language=objc
open /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg
# make sure xcrun can find SDKs
sudo xcode-select --switch /Applications/Xcode.app
# [iOS] build kiwix-lib
kiwix-build --target-platform iOS_multi kiwix-lib
# [macOS] build kiwix-lib
kiwix-build --target-platform native_static kiwix-lib
```

#### Create fat archive with all dependencies

This creates a single `.a` archive named libkiwix which contains all libkiwix's dependencies.
If you are to create an xcframework with multiple architectures/platforms, repeat this step for each:

* `native_static` (for macOS – x86_64)
* `iOS_x86_64`
* `iOS_arm64`

You'll have to do it for both iOS archs although you built it using `multi`.

```bash
libtool -static -o BUILD_<target>/INSTALL/lib/libkiwix.a BUILD_<target>/INSTALL/lib/*.a
```

#### Add fat archive to xcframework

```bash
xcodebuild -create-xcframework -library BUILD_<target>/INSTALL/lib/libkiwix.a -headers BUILD_<target>/INSTALL/include -output ../apple/Model/libkiwix.xcframework
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
