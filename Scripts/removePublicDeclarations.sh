#!/usr/bin/env bash
#
# Usage: ./removePublicDeclaracions.sh Sources/StreamNuke
#
# This script would iterate over the files on a particular directory, and perform basic replacement operations.
# It heavily relies on 'sed':
#     sed -i '<backup-file-extension>' -e 's/<original-string>/<replacement>/g' <file>
#             ^
#             Passing empty string prevents the creation of backup files

args=("$@")
directory=$1

files=`find $directory -name "*.swift"`
for f in $files
do
	`sed -i '' -e 's/public //g' -e 's/open //g' $f`

	# Nuke
	if [[ $directory == *"Nuke"* ]]; then
		`sed -i '' -e 's/var log/var nukeLog/g' \
			-e 's/log =/nukeLog =/g' \
			-e 's/signpost(log/signpost(nukeLog/g' \
			-e 's/ Cache(/ NukeCache(/g' \
			-e 's/ Cache</ NukeCache</g' $f`
		
		# Remove Cancellable interface duplicate
		if [[ $f == *"DataLoader"* && `head -10 $f` == *"protocol Cancellable"* ]]; then
			`sed -i '' -e '7,11d' $f`
		fi
	fi

	# Starscream
	if [[ $directory == *"Starscream"* ]]; then
		`sed -i '' -e 's/WebSocketClient/StarscreamWebSocketClient/g' $f`
		`sed -i '' -e 's/ConnectionEvent/StarscreamConnectionEvent/g' $f`
		`sed -i '' -e 's/: class {/: AnyObject {/g' $f`
	fi
done
