#!/bin/bash

dylibs=*.dylib

for file in $dylibs
do 
	install_name_tool -id @rpath/$file $file
	for dependency in $dylibs
	do
		install_name_tool -change $dependency @rpath/$dependency $file
	done
	install_name_tool -change /usr/lib/liblzma.5.dylib @rpath/liblzma.5.dylib $file
	otool -L $file
done