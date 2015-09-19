#!/bin/bash

VERSION=“5.0.5”
SDKVERSION="7.1"

ARCHS="armv7 armv7s arm64 i386 x86_64"
sudo xcode-select -s /Applications/Xcode.app
DEVELOPER=`xcode-select -print-path`

ROOT=$(pwd)
BUILDDIR="${ROOT}/build"

for ARCH in ${ARCHS}
do
	if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ];
	then
		PLATFORM="iPhoneSimulator"

		export IPHONEOS_DEPLOYMENT_TARGET="8.0"
		export CC="DEVELOPER/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
		export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot DEVELOPER/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk"
		export CPPFLAGS="-D__IPHONE_OS_VERSION_MIN_REQUIRED=${IPHONEOS_DEPLOYMENT_TARGET%%.*}0000"
		export LDFLAGS="-arch ${ARCH} -isysroot DEVELOPER/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk"
		./configure --disable-shared --enable-static --host="${ARCH}-apple-darwin" --prefix="${BUILDDIR}/${ARCH}"

	elif [ "${ARCH}" == "arm64" ];
	then
		PLATFORM="iPhoneOS"
		export IPHONEOS_DEPLOYMENT_TARGET="8.0"
		export CC="DEVELOPER/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
		export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot DEVELOPER/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk"
		export LDFLAGS="-arch ${ARCH} -isysroot DEVELOPER/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk"
		./configure --disable-shared --enable-static --host="arm-apple-darwin" --prefix="${BUILDDIR}/${ARCH}"
	else
		PLATFORM="iPhoneOS"
		export IPHONEOS_DEPLOYMENT_TARGET="8.0"
		export CC="DEVELOPER/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
		export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot DEVELOPER/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk"
		export LDFLAGS="-arch ${ARCH} -isysroot DEVELOPER/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk"
		./configure --disable-shared --enable-static --host="${ARCH}-apple-darwin" --prefix="${BUILDDIR}/${ARCH}"
	fi
    make && make install && make clean

done

mkdir -p "${BUILDDIR}/universal/lib"

cd "${BUILDDIR}/armv7/lib"
for file in *.a
do

cd ${BUILDDIR}
lipo -create armv7/lib/$file armv7s/lib/$file arm64/lib/$file i386/lib/$file x86_64/lib/$file -output universal/lib/$file

done

cp -r ${BUILDDIR}/armv7/include ${BUILDDIR}/universal/