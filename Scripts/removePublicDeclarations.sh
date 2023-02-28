#!/usr/bin/env bash
#
# Usage: ./removePublicDeclarations.sh Sources/StreamNuke
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

	# Nuke
	if [[ $directory == *"Nuke"* ]]; then
		replaceDeclaration 'var log' 'var nukeLog' $f
		replaceDeclaration 'log =' 'nukeLog =' $f
		replaceDeclaration 'signpost(log' 'signpost(nukeLog' $f
		replaceDeclaration ' Cache(' ' NukeCache(' $f
		replaceDeclaration ' Cache<' ' NukeCache<' $f
		
		# Remove Cancellable interface duplicate
		if [[ $f == *"DataLoader"* && `head -10 $f` == *"protocol Cancellable"* ]]; then
			`sed -i '' -e '7,11d' $f`
		fi
	fi

	# Starscream
	if [[ $directory == *"Starscream"* ]]; then
		replaceDeclaration 'WebSocketClient' 'StarscreamWebSocketClient' $f
		replaceDeclaration 'ConnectionEvent' 'StarscreamConnectionEvent' $f
		replaceDeclaration ': class {' ': AnyObject {' $f
	fi

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
done
