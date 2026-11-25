#!/usr/bin/env bash
#
# Usage: ./Scripts/updateCMark.sh 0.29.0.gfm.14
#
# Copies cmark-gfm's C sources from github/cmark-gfm into Sources/StreamChatAICMark, with the headers in include/, and
# prefixes its symbols. MarkdownUI bundles an older cmark-gfm, without upstream's later fixes, so update_markdownui
# leaves this target alone. Upstream, CMake generates a few headers: this target keeps its own copies of them, and
# writes the version header from the version given.

set -euo pipefail

version=${1:?"→ Missing version, such as 0.29.0.gfm.14"}
output_directory=Sources/StreamChatAICMark
kept_headers=(config.h cmark-gfm_export.h cmark_gfm.h module.modulemap)

if [[ ! $version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\.gfm\.([0-9]+)$ ]]; then
	echo "→ $version is not a cmark-gfm version, such as 0.29.0.gfm.14"
	exit 1
fi
major=${BASH_REMATCH[1]}
minor=${BASH_REMATCH[2]}
patch=${BASH_REMATCH[3]}
gfm=${BASH_REMATCH[4]}

workspace=$(mktemp -d)
trap 'rm -rf "$workspace"' EXIT

git clone --quiet --depth 1 --branch "$version" https://github.com/github/cmark-gfm.git "$workspace/cmark-gfm"
upstream=$workspace/cmark-gfm

for header in "${kept_headers[@]}"; do
	cp "$output_directory/include/$header" "$workspace/"
done

echo "→ Copying source files"
rm -rf "$output_directory"
mkdir -p "$output_directory/include"
for file in "$upstream"/src/*.c "$upstream"/extensions/*.c; do
	if [[ $(basename "$file") != main.c ]]; then
		cp "$file" "$output_directory/"
	fi
done
cp "$upstream"/src/*.inc "$output_directory/"
cp "$upstream"/src/*.h "$upstream"/extensions/*.h "$output_directory/include/"
for header in "${kept_headers[@]}"; do
	cp "$workspace/$header" "$output_directory/include/"
done
sed -e "s/@PROJECT_VERSION_MAJOR@/$major/g" \
	-e "s/@PROJECT_VERSION_MINOR@/$minor/g" \
	-e "s/@PROJECT_VERSION_PATCH@/$patch/g" \
	-e "s/@PROJECT_VERSION_GFM@/$gfm/g" \
	"$upstream/src/cmark-gfm_version.h.in" > "$output_directory/include/cmark-gfm_version.h"

./Scripts/prefixCSymbols.sh stream_ "$output_directory" Sources/StreamChatAI/StreamMarkdownUI
