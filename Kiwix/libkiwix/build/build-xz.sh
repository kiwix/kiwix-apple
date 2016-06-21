#!/bin/bash
ROOT=$(pwd)
XZ_FOLDER_NAME='xz-5.2.2'
##########################  XZ  ##########################

curl -O 'http://tukaani.org/xz/xz-5.2.2.tar.gz'
tar -xvzf xz-5.2.2.tar.gz

XZPATH=$ROOT/$XZ_FOLDER_NAME
cd $XZPATH

./autogen.sh

build_iOS()
{
	ARCH=$1
	
	if [ $ARCH == "i386" ] || [ $ARCH == "x86_64" ];
	then
		SDKROOT="$(xcodebuild -version -sdk iphonesimulator | grep -E '^Path' | sed 's/Path: //')"
	else
		SDKROOT="$(xcodebuild -version -sdk iphoneos | grep -E '^Path' | sed 's/Path: //')"
	fi

	export CC="$(xcrun -sdk iphoneos -find clang)"
	export CFLAGS="-fembed-bitcode -isysroot $SDKROOT -arch ${ARCH} -miphoneos-version-min=9.0"
	export LDFLAGS="-arch ${ARCH} -isysroot $SDKROOT"

	if [ $ARCH == "i386" ] || [ $ARCH == "x86_64" ];
	then
		./configure --prefix=$XZPATH/build/iOS/$ARCH --host=i686-apple-darwin11 --disable-static --enable-shared
	else
		./configure --prefix=$XZPATH/build/iOS/$ARCH --host=arm-apple-darwin --disable-static --enable-shared
	fi

	make && make install && make clean
}

build_OSX()
{
	ARCH=$1
	
	SDKROOT="$(xcodebuild -version -sdk macosx10.11 | grep -E '^Path' | sed 's/Path: //')"

	export CC="$(xcrun -sdk macosx10.11 -find clang)"
	export CFLAGS="-fembed-bitcode -isysroot $SDKROOT -arch ${ARCH} -mmacosx-version-min=10.6"
	export LDFLAGS="-arch ${ARCH} -isysroot $SDKROOT"

	./configure --prefix=$XZPATH/build/OSX/$ARCH --host=i686-apple-darwin11 --disable-static --enable-shared

	make && make install && make clean
}

distribute() {
	cd $XZPATH/build

	# iOS
	mkdir -p iOS/Universal/lib
	
	cd iOS/armv7/lib
	for file in *.a
	do
		cd $XZPATH/build
		lipo -create iOS/armv7/lib/$file iOS/armv7s/lib/$file iOS/arm64/lib/$file iOS/x86_64/lib/$file iOS/i386/lib/$file -output iOS/Universal/lib/$file
	done

	cd iOS/armv7/lib
	for file in *.dylib
	do
		cd $XZPATH/build
		lipo -create iOS/armv7/lib/$file iOS/armv7s/lib/$file iOS/arm64/lib/$file iOS/x86_64/lib/$file iOS/i386/lib/$file -output iOS/Universal/lib/$file
	done

	cd $XZPATH/build
	cp -r iOS/armv7/include iOS/Universal

	# OS X
	mkdir -p OSX/Universal/lib

	cd OSX/i386/lib
	for file in *.dylib
	do
		cd $XZPATH/build
		lipo -create OSX/x86_64/lib/$file OSX/i386/lib/$file -output OSX/Universal/lib/$file
	done
	
	cd $XZPATH/build
	cp -r OSX/x86_64/include OSX/Universal
}

build_iOS i386
build_iOS x86_64
build_iOS armv7
build_iOS armv7s
build_iOS arm64

build_OSX i386
build_OSX x86_64

distribute

