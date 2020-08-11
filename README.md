# Kiwix for iOS and macOS

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
* [CocoaPods](https://cocoapods.org/) `sudo gem install cocoapods && pod repo update`
* [kiwix-lib](https://github.com/kiwix/kiwix-lib)

### Building kiwix-lib

Instructions are available [on the kiwix-build repo](https://github.com/kiwix/kiwix-build).

```bash
git clone https://github.com/kiwix/kiwix-build.git
cd kiwix-build
# if on macOS mojave (10.14) or older, install headers to standard location
# https://developer.apple.com/documentation/xcode_release_notes/xcode_10_release_notes?language=objc
open /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg
kiwix-build --target-platform iOS_multi kiwix-lib
# assuming ../apple points to this repository
cp -vr BUILD_iOS_multi/INSTALL/include ../apple/Shared/Dependencies/
cp -vr BUILD_iOS_multi/INSTALL/lib ../apple/Shared/Dependencies/iOS_lib
```

### Building Kiwix iOS or Kiwix macOS

* Install Pods dependencies `pod install`
* Open project with Xcode `open Kiwix.xcworkspace`
* Change the App groups (in *Capabilities*) and Bundle Identifier for both iOS and Bookmarks targets
  * App Group must be different and unique (ex: `tld.mydomain.apple`)
  * iOS Bundle Identifier must be different and unique (ex: `tld.mydomain.apple.Kiwix`)
  * Bookmarks Bundle Identifier must be a child of iOS one (ex: `tld.mydomain.apple.Kiwix.Bookmarks`)
  * ⚠ if you are using a regular (non-paying) Apple Developer Account, you are limited in the number of App IDs you can use so be careful not to fumble much with those.
* Change the Signing profile to your account.
