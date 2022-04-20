#!/usr/bin/env bash
# Usage: ./bootstrap.sh
# This script will:
#   - install Mint and bootstrap its dependencies
#   - link git hooks
#   - install required ruby gems
#   - install sonar dependencies if `INSTALL_SONAR` environment variable is provided
# You should have homebrew installed.
# If you get `zsh: permission denied: ./bootstrap.sh` error, please run `chmod +x bootstrap.sh` first

function puts {
  echo
  echo -e "👉 ${1}"
}

# Check if Homebrew is installed
if [[ $(command -v brew) == "" ]]; then
    echo "Homebrew not installed. Please install."
    exit 1
fi

set -Eeuo pipefail

trap "echo ; echo ❌ The Bootstrap script failed to finish without error. See the log above to debug. ; echo" ERR

puts "Install Mint if needed"
# List installed Mint versions, if fails, install Mint
brew list mint || brew install mint

# Set bash to Strict Mode (http://redsymbol.net/articles/unofficial-bash-strict-mode/)
set -euo pipefail

puts "Bootstrap Mint dependencies"
mint bootstrap

puts "Create git/hooks folder if needed"
mkdir -p .git/hooks

# Symlink hooks folder to .git/hooks folder
puts "Create symlink for pre-commit hooks"
# Symlink needs to be ../../hooks and not ./hooks because git evaluates them in .git/hooks
ln -sf ../../hooks/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
chmod +x ./hooks/git-format-staged

# Install gems
puts "Install bundle dependencies"
bundle install

if [[ ${INSTALL_SONAR-default} == true ]]; then
    puts "Install sonar dependencies"
    pip install lizard
    brew install sonar-scanner
fi

# Copy internal Xcode scheme to the right folder for
echo
echo -e "👉 Adding DemoApp-StreamDevelopers.xcscheme to the Xcode project"
cp Scripts/DemoApp-StreamDevelopers.xcscheme StreamChat.xcodeproj/xcshareddata/xcschemes/DemoApp-StreamDevelopers.xcscheme
