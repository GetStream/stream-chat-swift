#!/usr/bin/env bash
#
# Usage: ./prefixCSymbols.sh stream_ Sources/StreamChatAICMark Sources/StreamChatAI/StreamMarkdownUI
#
# This script adds a prefix to every global symbol of an embedded C library, in its sources and in the Swift sources
# calling it. Without it, an app that also links its own copy of the library (e.g. cmark-gfm through swift-markdown-ui)
# fails with duplicate symbols.

args=("$@")
prefix=$1
c_directory=$2
swift_directory=$3

exported_symbols() {
	objects_directory=$(mktemp -d)
	for f in `find $c_directory -name "*.c"`
	do
		xcrun clang -c -w -I $c_directory/include $f -o $objects_directory/$(basename $f .c).o || exit 1
	done
	# Mach-O adds a leading underscore to C names
	nm -gUj $objects_directory/*.o | grep -v -e ':$' -e '^$' | sed 's/^_//' | sort -u
	rm -rf $objects_directory
}

symbols=$(exported_symbols) || exit 1
files=`find $c_directory $swift_directory -type f \( -name "*.c" -o -name "*.h" -o -name "*.inc" -o -name "*.swift" \)`

echo "→ Prefixing $(echo "$symbols" | wc -l | xargs) symbols with $prefix"
for symbol in $symbols
do
	sed -i '' -e "s/[[:<:]]$symbol[[:>:]]/$prefix$symbol/g" $files
done

prefixed_symbols=$(exported_symbols) || exit 1
for symbol in $prefixed_symbols
do
	if [[ $symbol != $prefix* ]]; then
		echo "→ $symbol is still not prefixed"
		exit 1
	fi
done
