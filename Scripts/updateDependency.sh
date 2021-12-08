#!/usr/bin/env bash
#
# Usage: ./updateDependency.sh 10.3.3 Dependencies/Nuke Sources/StreamNuke Sources
#
# This script gets the source code of a dependency of a given library, and copies it to our codebase

ensure_clean_git () {
	if !(git diff-index --quiet HEAD)
	then
		echo "→ Seems like git is not clean in $dependency_directory. Please make sure it is clean, and run it again"
		exit 1
	fi
}

args=("$@")
version=$1
dependency_directory=$2
output_directory=$3
sources_directory=$4

git submodule update --init
cd $dependency_directory

ensure_clean_git

git fetch --tags
git checkout $version

ensure_clean_git

cd -

rm -rf $output_directory
mkdir $output_directory
cp -r "$dependency_directory/$sources_directory/." $output_directory


for f in `find $output_directory -type f \( -iname \*.h -o -iname \*.plist \)`
do
	echo "→ Removing $f"
	rm $f
done
