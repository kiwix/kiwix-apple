#!/bin/bash

ROOT=$(pwd)

##########################  ZIM  ##########################

cd icu
ICU_PATH="$(pwd)"
ICU_SOURCE_PATH=$ICU_PATH/source
ICU_FLAGS="-I$ICU_PATH/source/common/ -I$ICU_PATH/source/tools/tzcode/"

build_iOS()
{
	cd $ROOT
	ARCH=$1
	
	if [ $ARCH == "i386" ] || [ $ARCH == "x86_64" ];
	then
		SDKROOT="$(xcodebuild -version -sdk iphonesimulator | grep -E '^Path' | sed 's/Path: //')"
	else
		SDKROOT="$(xcodebuild -version -sdk iphoneos | grep -E '^Path' | sed 's/Path: //')"
	fi

	export CC="$(xcrun -sdk iphoneos -find clang)"
	export CFLAGS="-fembed-bitcode -isysroot $SDKROOT -I$SDKROOT/usr/include/ -I./include/ -arch $ARCH -miphoneos-version-min=7.0 $ICU_FLAGS"

	export CXX="$(xcrun -sdk iphoneos -find clang++)"
	export CXXFLAGS="$CFLAGS -stdlib=libc++ -std=c++11"

	#export CPP="$CC -E"
	#export CPPFLAGS="$CFLAGS"

	export LDFLAGS="-arch ${ARCH} -isysroot $SDKROOT"

	mkdir -p build-$ARCH && cd build-$ARCH
	[ -e Makefile ] && make distclean

	if [ $ARCH == "i386" ] || [ $ARCH == "x86_64" ];
	then
		$ICU_PATH/source/configure --prefix=$ROOT/build-$ARCH --host=i686-apple-darwin11 --enable-static --disable-shared
	else
		$ICU_PATH/source/configure --prefix=$ROOT/build-$ARCH --host=arm-apple-darwin --enable-static --disable-shared -with-cross-build=$ROOT/build-i386
	fi

	make
}

build_OSX()
{
	ARCH=$1
	
	cd $ICU_SOURCE_PATH

	SDKROOT="$(xcodebuild -version -sdk macosx10.11 | grep -E '^Path' | sed 's/Path: //')"

	export CC="$(xcrun -sdk macosx10.11 -find clang)"
	export CFLAGS="-fembed-bitcode -isysroot $SDKROOT -arch ${ARCH} -mmacosx-version-min=10.10 $ICU_FLAGS"

	export CPP="$CC -E"
	export CPPFLAGS="$CFLAGS"

	export LDFLAGS="-arch ${ARCH} -isysroot $SDKROOT"

	./configure --prefix=$(pwd)/build/OSX/$ARCH --host=i686-apple-darwin11 --disable-static --enable-shared

	make && make install && make clean
}

distribute() {
	cd $ICU_SOURCE_PATH/build
	mkdir -p Universal/iOS/lib
	mkdir -p Universal/OSX/lib

	# cd iOS/armv7/lib
	# for file in *.a
	# do
	# 	cd $ICU_SOURCE_PATH/build
	# 	lipo -create iOS/armv7/lib/$file iOS/armv7s/lib/$file iOS/arm64/lib/$file iOS/x86_64/lib/$file iOS/i386/lib/$file -output Universal/iOS/lib/$file
	# done

	cd OSX/i386/lib
	for file in *.dylib
	do
		cd $ICU_SOURCE_PATH/build
		lipo -create OSX/x86_64/lib/$file OSX/i386/lib/$file -output Universal/OSX/lib/$file
	done
	
	# cd $ICU_SOURCE_PATH/build
	# mkdir -p Universal/include
	# cp -r iOS/armv7/include Universal
}

# build_iOS i386
# build_iOS x86_64
# build_iOS armv7
# build_iOS armv7s
# build_iOS arm64

# build_OSX i386
# build_OSX x86_64

distribute

# cd $ROOT
# mkdir -p build-universal/lib

# cd build-armv7s/lib
# for file in *.a
# do
# 	cd $ROOT
# 	lipo -create build-armv7/lib/$file build-armv7s/lib/$file build-arm64/lib/$file build-i386/lib/$file build-x86_64/lib/$file -output build-universal/lib/$file
# done

# cd $ROOT/build-armv7
# make install
# cp -r $ROOT/build-armv7/include/unicode $ROOT/build-universal/unicode