#!/usr/bin/env bash
# Usage: ./bootstrap.sh
# This script will install Mint and bootstrap its dependencies, link git hooks and install required ruby gems.
# You should have homebrew installed.
# If you get `zsh: permission denied: ./bootstrap.sh` error, please run `chmod +x bootstrap.sh` first

# Check if Homebrew is installed
if [[ $(command -v brew) == "" ]]; then
    echo "Homebrew not installed. Please install."
    exit 1
fi

echo
echo -e "👉 Install Mint if needed"
# List installed Mint versions, if fails, install Mint
brew list mint || brew install mint

# Set bash to Strict Mode (http://redsymbol.net/articles/unofficial-bash-strict-mode/)
set -euo pipefail

echo
echo -e "👉 Bootstrap Mint dependencies"
mint bootstrap

# Symlink hooks folder to .git/hooks folder
echo
echo -e "👉 Create symlink for pre-commit hooks"
# Symlink needs to be ../../hooks and not ./hooks because git evaluates them in .git/hooks
ln -sf ../../hooks/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
chmod +x ./hooks/git-format-staged

# Get SwiftLint version from Mintfile to be used by danger-swiftlint too
SWIFTLINT_VERSION=$(cat Mintfile | grep SwiftLint | awk -F@ '{print $2}')

# Install gems
echo
echo -e "👉 Install bundle dependencies"
echo "SwiftLint version: " $SWIFTLINT_VERSION
bundle config SWIFTLINT_VERSION "$SWIFTLINT_VERSION"
bundle install
