#!/bin/bash

VERSION=“5.2.0”
SDKVERSION="8.4"

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
		echo ${ARCH};
		export IPHONEOS_DEPLOYMENT_TARGET="8.0"
		export CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
		export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk -I/Users/chrisli/Developer/xz-5.2.0/build/${ARCH}/include"
		export CPPFLAGS="-D__IPHONE_OS_VERSION_MIN_REQUIRED=${IPHONEOS_DEPLOYMENT_TARGET%%.*}0000"
		export CXX="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -lstdc++ -lc++.1 -lc++ -lc++abi -lstdc++.6.0.9 -lstdc++.6"
		export CXXFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk -I/Users/chrisli/Developer/xz-5.2.0/build/${ARCH}/include"
		export LDFLAGS="-arch ${ARCH} -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk -L/Users/chrisli/Developer/xz-5.2.0/build/${ARCH}/lib"
		./configure --disable-shared --enable-static --host="${ARCH}-apple-darwin" --prefix="${BUILDDIR}/${ARCH}" --enable-FEATURE=yes

	elif [ "${ARCH}" == "arm64" ];
	then
		PLATFORM="iPhoneOS"
		echo iPhoneOS;
		export IPHONEOS_DEPLOYMENT_TARGET="7.0"
		export CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
		export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk -I/Users/chrisli/Developer/xz-5.2.0/build/${ARCH}/include"
		export CXX="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -lstdc++ -lc++.1 -lc++ -lc++abi -lstdc++.6.0.9 -lstdc++.6"
		export CXXFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk -I/Users/chrisli/Developer/xz-5.2.0/build/${ARCH}/include"
		export LDFLAGS="-arch ${ARCH} -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk -L/Users/chrisli/Developer/xz-5.2.0/build/${ARCH}/lib"
		./configure --disable-shared --enable-static --host="arm-apple-darwin" --prefix="${BUILDDIR}/${ARCH}" --enable-FEATURE=yes
	else
		PLATFORM="iPhoneOS"
		echo ${ARCH};
		export IPHONEOS_DEPLOYMENT_TARGET="8.0"
		export CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
		export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk -I/Users/chrisli/Developer/xz-5.2.0/build/${ARCH}/include"
		export CXX="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -lstdc++ -lc++.1 -lc++ -lc++abi -lstdc++.6.0.9 -lstdc++.6"
		export CXXFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk -I/Users/chrisli/Developer/xz-5.2.0/build/${ARCH}/include"
		export LDFLAGS="-arch ${ARCH} -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}8.4.sdk -L/Users/chrisli/Developer/xz-5.2.0/build/${ARCH}/lib"
		./configure --disable-shared --enable-static --host="${ARCH}-apple-darwin" --prefix="${BUILDDIR}/${ARCH}" --enable-FEATURE=yes
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

