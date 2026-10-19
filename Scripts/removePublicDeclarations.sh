#!/usr/bin/env bash
#
# Usage: ./removePublicDeclarations.sh Sources/StreamChatUI/StreamSwiftyGif
#
# This script would iterate over the files on a particular directory, and perform basic replacement operations.
# It heavily relies on 'sed':
#     sed -i '<backup-file-extension>' -e 's/<original-string>/<replacement>/g' <file>
#             ^
#             Passing empty string prevents the creation of backup files

args=("$@")
directory=$1

replaceDeclaration() {
	original=$1
	replacement=$2
	file=$3
	`sed -i '' -e "s/$original/$replacement/g" $file`
}

files=`find $directory -name "*.swift"`
for f in $files
do
	replaceDeclaration 'public internal(set) ' '' $f 
	replaceDeclaration 'open ' '' $f
	replaceDeclaration 'public ' '' $f

	# DiffernceKit
	if [[ $directory == *"DifferenceKit"* ]]; then
		# For DifferenceKit we need to change some declarations to public
		# because is uses the @inlinable attribute in some places

		replaceDeclaration 'protocol ContentEquatable' 'public protocol ContentEquatable' $f
		replaceDeclaration 'protocol ContentIdentifiable {' 'public protocol ContentIdentifiable {' $f
		replaceDeclaration 'struct ElementPath: Hashable {' 'public struct ElementPath: Hashable {' $f
		replaceDeclaration 'var element: Int' 'public var element: Int' $f
		replaceDeclaration 'var section: Int' 'public var section: Int' $f
		replaceDeclaration 'var debugDescription: String' 'public var debugDescription: String' $f
		
		replaceDeclaration 'func isContentEqual(to source: Wrapped?) -> Bool {' \
		'public func isContentEqual(to source: Wrapped?) -> Bool {' \
		$f

		replaceDeclaration 'func isContentEqual(to source: \[Element\]) -> Bool' \
		'public func isContentEqual(to source: \[Element\]) -> Bool' \
		$f

		replaceDeclaration 'extension ContentIdentifiable where Self: Hashable {' \
		'public extension ContentIdentifiable where Self: Hashable {' \
		$f
		
		replaceDeclaration 'typealias Differentiable =' 'public typealias Differentiable =' $f
	fi

	# Splash
	if [[ $directory == *"Splash"* ]]; then
		# Splash's names would hide SwiftUI's Color and Font, and clash with MarkdownUI's Theme
		replaceDeclaration '[[:<:]]Color[[:>:]]' 'SplashColor' $f
		replaceDeclaration '[[:<:]]Font[[:>:]]' 'SplashFont' $f
		replaceDeclaration '[[:<:]]Theme[[:>:]]' 'SplashTheme' $f
	fi

	# MarkdownUI
	if [[ $directory == *"MarkdownUI"* ]]; then
		replaceDeclaration '@frozen ' '' $f
		# NetworkImage is embedded in the same module
		replaceDeclaration '^import NetworkImage$' '' $f
		replaceDeclaration '@_implementationOnly import cmark_gfm' 'internal import StreamChatAICMark' $f
		# StreamChatAI has its own CodeBlockView
		replaceDeclaration '[[:<:]]CodeBlockView[[:>:]]' 'MarkdownCodeBlockView' $f
	fi
done

# File names must be unique in a module
if [[ $directory == *"Splash"* ]]; then
	for f in `find $directory -name "Color.swift" -o -name "Font.swift" -o -name "Theme*.swift"`
	do
		mv $f "$(dirname $f)/Splash$(basename $f)"
	done
fi

if [[ $directory == *"MarkdownUI"* ]]; then
	for f in `find $directory -name "CodeBlockView.swift"`
	do
		mv $f "$(dirname $f)/Markdown$(basename $f)"
	done
fi
