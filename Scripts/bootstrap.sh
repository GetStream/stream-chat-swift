#!/usr/bin/env bash
# shellcheck source=/dev/null
# Usage: ./bootstrap.sh
# This script will:
#   - install Mint and bootstrap its dependencies
#   - install Vale
#   - link git hooks
#   - install allure dependencies if `INSTALL_ALLURE` environment variable is provided
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

# Set bash to Strict Mode (http://redsymbol.net/articles/unofficial-bash-strict-mode/)
set -Eeuo pipefail

trap "echo ; echo ❌ The Bootstrap script failed to finish without error. See the log above to debug. ; echo" ERR

source ./Githubfile

puts "Create git/hooks folder if needed"
mkdir -p .git/hooks

# Symlink hooks folder to .git/hooks folder
puts "Create symlink for pre-commit hooks"
# Symlink needs to be ../../hooks and not ./hooks because git evaluates them in .git/hooks
ln -sf ../../hooks/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
chmod +x ./hooks/git-format-staged

puts "Install brew dependencies"
brew bundle -d

puts "Bootstrap Mint dependencies"
mint bootstrap --link

# Copy internal Xcode scheme to the right folder for
puts "Adding DemoApp-StreamDevelopers.xcscheme to the Xcode project"
cp Scripts/DemoApp-StreamDevelopers.xcscheme StreamChat.xcodeproj/xcshareddata/xcschemes/DemoApp-StreamDevelopers.xcscheme

if [[ ${INSTALL_ALLURE-default} == true ]]; then
  puts "Install allurectl"
  DOWNLOAD_URL="https://github.com/allure-framework/allurectl/releases/download/${ALLURECTL_VERSION}/allurectl_darwin_amd64"
  curl -sL "${DOWNLOAD_URL}" -o ./fastlane/allurectl
  chmod +x ./fastlane/allurectl

  puts "Install xcresults"
  DOWNLOAD_URL="https://github.com/eroshenkoam/xcresults/releases/download/${XCRESULTS_VERSION}/xcresults"
  curl -sL "${DOWNLOAD_URL}" -o ./fastlane/xcresults
  chmod +x ./fastlane/xcresults
fi
