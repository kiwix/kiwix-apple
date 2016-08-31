#!/bin/bash

dylibs=*.dylib

for file in $dylibs
do 
	install_name_tool -id @rpath/$file $file
	for dependency in $dylibs
	do
		install_name_tool -change $dependency @rpath/$dependency $file
	done
	install_name_tool -change /Volumes/Data/Developer/build/xz-5.2.2/build/iOS/x86_64/lib/liblzma.5.dylib @rpath/liblzma.5.dylib liblzma.5.dylib
	otool -L $file
done