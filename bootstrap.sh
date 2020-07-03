#!/usr/bin/env bash
# Usage: ./bootstrap.sh
# This script will install swiftformat, link git hooks and install required ruby gems.
# You should have homebrew installed.
# If you get `zsh: permission denied: ./bootstrap.sh` error, please run `chmod +x bootstrap.sh` first

# Install swiftformat
brew install swiftformat

# Set bash to Strict Mode (http://redsymbol.net/articles/unofficial-bash-strict-mode/)
set -euo pipefail

# Symlink hooks folder to .git/hooks folder
ln -s ../../hooks/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
echo "Symlink for pre-commit created successfully"

# git-format-staged
chmod +x hooks/git-format-staged
echo "chmod +x for git-format-staged set successfully"

# Install gems
bundle install
