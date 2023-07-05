#!/usr/bin/env bash
# shellcheck source=/dev/null
# Usage: ./bootstrap.sh
# This script will:
#   - install Mint and bootstrap its dependencies
#   - install Vale
#   - link git hooks
#   - install required ruby gems
#   - install sonar dependencies if `INSTALL_SONAR` environment variable is provided
#   - install allure dependencies if `INSTALL_ALLURE` environment variable is provided
#   - install xcparse if `INSTALL_XCPARSE` environment variable is provided
#   - install pythond dependencies if `SYNC_MOCK_SERVER` environment variable is provided
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

puts "Install Vale if needed"
brew install vale

puts "Install bundle dependencies"
bundle install

if [[ ${XCODE_ACTIONS-default} == default ]]; then
  puts "Install Mint if needed"
  brew install mint

  puts "Bootstrap Mint dependencies"
  mint bootstrap --link

  # https://github.com/GetStream/ios-issues-tracking/issues/265
  if [[ $(sw_vers -productVersion) != *"11."* ]]; then
    puts "Install RobotsAndPencils/xcodes"
    mint install RobotsAndPencils/xcodes@1.4.1 -l
  fi

  # Copy internal Xcode scheme to the right folder for
  puts "Adding DemoApp-StreamDevelopers.xcscheme to the Xcode project"
  cp Scripts/DemoApp-StreamDevelopers.xcscheme StreamChat.xcodeproj/xcshareddata/xcschemes/DemoApp-StreamDevelopers.xcscheme
fi

if [[ ${INSTALL_SONAR-default} == true ]]; then
  puts "Install sonar dependencies"
  pip install lizard
  brew install sonar-scanner
fi

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

if [[ ${INSTALL_XCPARSE-default} == true ]]; then
  brew install chargepoint/xcparse/xcparse
fi

if [[ ${SYNC_MOCK_SERVER-default} == true ]]; then
  pip install -r requirements.txt
fi
