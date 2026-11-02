#!/bin/sh
# Copies upstream's spec/ folder (language.md, overview.md, prompt.md, fixtures/1.0/**) unchanged.
# Usage: ./copy-spec.sh <openui-clone> <dest-dir>
set -eu
[ $# -eq 2 ] || { echo "usage: $0 <openui-clone> <dest-dir>" >&2; exit 2; }
mkdir -p "$2"
cp "$1"/spec/*.md "$2"/
mkdir -p "$2/fixtures"
cp -R "$1/spec/fixtures/1.0" "$2/fixtures/"
echo "spec from $(git -C "$1" rev-parse --short HEAD) copied to $2"
