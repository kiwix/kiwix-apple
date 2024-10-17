# Kiwix for Apple iOS & macOS

This is the home for Kiwix apps for Apple iOS and macOS.

[![CodeFactor](https://www.codefactor.io/repository/github/kiwix/kiwix-apple/badge)](https://www.codefactor.io/repository/github/kiwix/kiwix-apple)
[![CI Build Status](https://github.com/kiwix/kiwix-apple/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/kiwix/kiwix-apple/actions/workflows/ci.yml?query=branch%3Amain)
[![CD Build Status](https://github.com/kiwix/kiwix-apple/actions/workflows/cd.yml/badge.svg?branch=main)](https://github.com/kiwix/kiwix-apple/actions/workflows/cd?query=branch%3Amain)
[![Codecov](https://codecov.io/gh/kiwix/kiwix-apple/branch/main/graph/badge.svg)](https://codecov.io/gh/kiwix/kiwix-apple)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
<img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Drawing="/>
[![Join Slack](https://img.shields.io/badge/Join%20us%20on%20Slack%20%23kiwix--apple-2EB67D)](https://slack.kiwix.org)

## Download

Kiwix apps are made available primarily via the [App Store](https://ios.kiwix.org) and [Mac App Store](https://macos.kiwix.org). macOS version can also be [downloaded directly](https://download.kiwix.org/release/kiwix-desktop-macos/kiwix-desktop-macos.dmg).

Most recent versions of Kiwix support the three latest major versions of the
OSes (either iOS or macOS). Older versions of Kiwix being still
downloadable for older versions of macOS and iOS on the Mac App Store.

## Known bugs

* ZIM files including video content work only properly from Kiwix
  version `3.4.0`, from iOS/iPadOs `17.0` and from macOS `14.0`. With
  older versions of Kiwix or OSes, videos might work, but the full
  support is not guaranted and bugs won't be investigated further. The
  reasons behind this is the lack (only recent) support of open video
  formats used in the ZIM files.

## Develop

Kiwix developers usually work with latest macOS and Xcode. Check our [Continuous Integration Workflow](https://github.com/kiwix/kiwix-apple/blob/main/.github/workflows/ci.yml) to find out which Xcode version we use on Github Actions.

### Get started

To get started, you will need the following:

* An [Apple Developer account](https://developer.apple.com) (doesn't require membership)
* [Xcode](https://developer.apple.com/xcode/) installed
* Its command-line utilities (`xcode-select --install`)
* [Homebrew](https://brew.sh) installed

### Steps
 1) clone this repository
 2) from the project folder **run the following command: `brew bundle`**

### Xcode settings

To compile and run Kiwix from Xcode locally, you will need to:
* Change the Bundle Identifier (in *Signing & Capabilities*)
* Select appropriate Signing Certificate/Profile.
* It is recommended to enable:

`Xcode settings > Text Editing > Editing`
> "While Editing":
> - ✅ "Automatically trim trailing whitespace"
> - ✅ "Include whitespace-only lines"

### Dependencies installed for you
Our `Brewfile` will install all the necessary dependencies for you:
- our `CoreKiwix.xcframework` ([libkiwix](https://github.com/kiwix/libkiwix) and [libzim](https://github.com/openzim/libzim)) - the version of which is specified in the `Brewfile`
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) which will create the project files for you

### How XcodeGen is working?
Xcode project files are not directly contained within this repository, instead they are generated for you automatically (as git hooks on post-merge, post-checkout, post-rewrite - see the `.pre-commit-config.yaml`).

This means, that you can work in Xcode as usual, but you don't need to worry about the project file changes anymore.

Contributors: please note, **changes to the Xcode project folder will not be tracked by git**.

If you wish to change any settings as part of your contribution, please **edit the `project.yml` file instead.**

Please refer to the [XcodeGen documentation](https://github.com/yonaskolb/XcodeGen) for further details.

### CPU Architectures

Kiwix compiles on both macOS architectures x86_64 and arm64 (Apple silicon).

Kiwix for iOS and macOS can run, in both cases, on x86_64 or arm64.

### Switch to another version of the `CoreKiwix.xcframework`

`CoreKiwix.xcframework` is published with all supported platforms and CPU architectures:

- [latest release](https://download.kiwix.org/release/libkiwix/libkiwix_xcframework.tar.gz)
- [latest nightly](https://download.kiwix.org/nightly/libkiwix_xcframework.tar.gz): using `main` branch of both `libkiwix` and `libzim`.

In order to use another version of CoreKiwix, than the one pre-installed, you can simply replace the CoreKiwix.xcframework folder at the root of the project with the version downloaded, and unpacked.

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

kiwix-build --config apple_all_static libkiwix
# assuming your kiwix-build and apple folder at at same level
cp -r BUILD_apple_all_static/INSTALL/lib/CoreKiwix.xcframework ../apple/
```

You can now launch the build from Xcode and use the iOS simulator or
your macOS target. At this point the xcframework is not signed.


### Debug webviews

In development builds (run from Xcode) it is possible to debug the
web-views via Safari development menu.

If Kiwix iOS runs on a device (iPhone or iPad), you need to connect
the device to your macOS device via an USB cable.

If Kiwix for macOS or iOS runs in simulator it will work out of the box
in this regard.

For a detailed explanation of the web-development mode, please see
Apple's documentation:
https://developer.apple.com/documentation/safari-developer-tools/inspecting-ios

## Deployment

### Nightly to FTP

Each night 01:32 am CET, we build our iOS and macOS apps.
These are developer signed builds, notarized (a process required to install them outside of the app store) and uploaded to our FTP nightly folder. The files are versioned using the current date.

### Weekly to TestFlight

Mondays at 02:00 am CET, we build our apps, but only if there were code changes within the last week (any git commits to main).
These are AppStore builds, which are uploaded to TestFlight, using the current app version from code (see `project.yml`).

### On-demand TestFlight

It is also possible to create TestFlight builds on-demand, by pushing a git tag named "testflight" to the repo. Please note we are overwriting the very same tag for consequent testflight releases. This will run the same process as the "weekly" build (we just do not need to wait a whole week).

### Releasing to AppStore and FTP

Once we are happy with the quality of the app in TestFlight, we can send it for approval to Apple. Once approved by Apple, we can release them to the AppStore. At the same time, we do want to release our macOS app via FTP as well. For this, we run our "Post App Release" workflow, which can be triggered by creating a Github Release, based on the git commit used for the TestFlight apps (the ones that were approved by Apple). The specific commit that triggered the (now approved) TestFlight app, can be found under Github Actions.
Based on this commit we should create a new tag with the release (semantic) version, and use this tag for GitHub Release.
This Github Release will rebuild the macOS application and upload it to FTP to the release folder. Again, the purpose of this is to make the very same macOS app - which was released to the AppStore  - also available via FTP.
In case the app is rejected by Apple in a way that requires a new build to fix the issue, a new patch version should be created, and re-submitted to App Store.

### Last step

If all that is done, we should create a PR, incrementing the version number of the project (see: `project.yml`), and the deployment cycle can start again.

## Reporting a bug

* Bug reports and features requests should be done [online](https://github.com/kiwix/kiwix-apple/issues).
* Follow [issue reporting good
  practices](https://github.com/kiwix/overview/blob/main/REPORT_BUG.md).
* On macOS - if requested by a maintainer - pack your Kiwix app
  container with the following command (then make it available
  somewhere online): `tar -czvf ~/Documents/self.Kiwix.tgz
  ~/Library/Containers/self.Kiwix`.

## License

[GPLv3](https://www.gnu.org/licenses/gpl-3.0) or later, see
[LICENSE](LICENSE) for more details.
