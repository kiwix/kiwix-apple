#!/bin/bash

SDKVERSION="8.4"

ARCHS="armv7"
DEVELOPER=`xcode-select -print-path`

ROOT=$(pwd)
BUILDDIR="${ROOT}/build"

for ARCH in ${ARCHS}
do
	if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ];
	then
		PLATFORM="iPhoneSimulator"

		export IPHONEOS_DEPLOYMENT_TARGET="8.0"
		export CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
		export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk"
		export CPPFLAGS="-D__IPHONE_OS_VERSION_MIN_REQUIRED=${IPHONEOS_DEPLOYMENT_TARGET%%.*}0000"
		export CXX="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -lstdc++"
		export CXXFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk"
		export LDFLAGS="-arch ${ARCH} -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk"
		./configure --disable-shared --enable-static --host="${ARCH}-apple-darwin" --prefix="${BUILDDIR}/${ARCH}" --with-cross-build="/Users/chrisli/Developer/icu/source/build/MacOS"

	elif [ "${ARCH}" == "arm64" ];
	then
		PLATFORM="iPhoneOS"
		export IPHONEOS_DEPLOYMENT_TARGET="8.0"
		export CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
		export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk"
		export CXX="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -lstdc++"
		export CXXFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk"
		export LDFLAGS="-arch ${ARCH} -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk"
		./configure --disable-shared --enable-static --host="arm-apple-darwin" --prefix="${BUILDDIR}/${ARCH}" --with-cross-build="/Users/chrisli/Developer/icu/source/build/MacOS"
	else
		PLATFORM="iPhoneOS"
		export IPHONEOS_DEPLOYMENT_TARGET="8.0"
		export CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
		export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk"
		export CXX="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -lstdc++"
		export CXXFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk"
		export LDFLAGS="-arch ${ARCH} -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk"
		./configure --disable-shared --enable-static --host="${ARCH}-apple-darwin" --prefix="${BUILDDIR}/${ARCH}" --with-cross-build="/Users/chrisli/Developer/icu/source/build/MacOS"
	fi
    

done

mkdir -p "${BUILDDIR}/universal/lib"

cd "${BUILDDIR}/armv7/lib"
for file in *.a
do

cd ${BUILDDIR}
lipo -create armv7/lib/$file armv7s/lib/$file arm64/lib/$file i386/lib/$file x86_64/lib/$file -output universal/lib/$file

done

cp -r ${BUILDDIR}/armv7/include ${BUILDDIR}/universal/