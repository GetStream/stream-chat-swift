#!/usr/bin/env bash
#
# Usage: ./removeUnneededSymbols.sh StreamChatUI ./Products
#
# Creating an xcframework for StreamChatUI generates a .bcsymbolmap file for itself, and one for
# each of its dependencies too (eg. StreamChat). That means that we will end up having something like:
#
# -> StreamChatUI/BCSymbolMaps/
#                              <UUID-StreamChatUI>.bcsymbolmap
#                              <UUID-StreamChat>.bcsymbolmap
# -> StreamChat/BCSymbolMaps/
#                              <UUID-StreamChat>.bcsymbolmap
#
# When adding both StreamChat and StreamChatUI to an app, it will throw an error when trying to compile
# saying that there are multiple executions producing the same file (<UUID-StreamChat>.bcsymbolmap).
#
# This script will remove duplicated .bcsymbolmap in the generated xcframeworks.
# If we countinue with the same example, it will leave it as follows:
#
# -> StreamChatUI/BCSymbolMaps/
#                              <UUID-StreamChatUI>.bcsymbolmap
# -> StreamChat/BCSymbolMaps/
#                              <UUID-StreamChat>.bcsymbolmap
#
# Each xcframework only contains its symbols now.

args=("$@")
library=$1
output_directory=$2

function removeUnneededSymbols() {
	arch=$1
	path="$output_directory/$library.xcframework/$arch/BCSymbolMaps"
	cd $path

	# Looking for [...]/DerivedSources/[LIBRARY-NAME]_vers.c
	regex="(\/DerivedSources\/)([a-zA-Z_]*)(_vers.c)"
	files="*.bcsymbolmap"
	for f in $files
	do
		text=`head -10 $f`
	    [[ $text =~ $regex ]]
	    library_match="${BASH_REMATCH[2]}"
	    if [[ $library_match != $library ]]
	    then 
	    	echo "→ Removing uneeded 'bcsymbolmap' from $library-$arch: $library_match - $f"
	    	rm $f
	    fi
	done

	cd - >/dev/null
}

removeUnneededSymbols "ios-arm64"
removeUnneededSymbols "ios-arm64_x86_64-simulator"