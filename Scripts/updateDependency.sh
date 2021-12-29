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

dependency_url=""

# Nuke
if [[ $dependency_directory == *"Nuke"* ]]; then
	dependency_url="git@github.com:kean/Nuke.git"
elif [[ $dependency_directory == *"SwiftyGif"* ]]; then
	dependency_url="git@github.com:kirualex/SwiftyGif.git"
elif [[ $dependency_directory == *"Starscream"* ]]; then
	dependency_url="git@github.com:daltoniam/Starscream.git"
else
	echo "→ Unknown dependency at $dependency_directory"
	exit 1
fi

if ! [[ -d "$dependency_directory" ]]; then
    echo "→ $dependency_directory does not exist in your filesystem. Cloning the repo"
    git clone $dependency_url $dependency_directory
fi

cd $dependency_directory

ensure_clean_git

git fetch --tags
git checkout $version

ensure_clean_git

cd -

echo "→ Copying source files"
rm -rf $output_directory
mkdir $output_directory
cp -r "$dependency_directory/$sources_directory/." $output_directory


for f in `find $output_directory -type f \( -iname \*.h -o -iname \*.plist \)`
do
	echo "→ Removing $f"
	rm $f
done

rm -rf $dependency_directory
