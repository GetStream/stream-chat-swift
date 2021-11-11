#!/usr/bin/env bash

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