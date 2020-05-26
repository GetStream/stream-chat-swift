#!/usr/bin/env bash
# Usage: ./bootstrap.sh
# This script will install swiftformat, link git hooks and install required ruby gems.
# You should have homebrew installed.
# If you get `zsh: permission denied: ./bootstrap.sh` error, please run `chmod +x bootstrap.sh` first

# Install swiftformat
brew install swiftformat

# Symlink hooks folder to .git/hooks folder
set -eu
ln -s ../../hooks/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
echo "Symlink created successfully"

# Install gems
bundle install

