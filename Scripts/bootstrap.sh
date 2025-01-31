#!/usr/bin/env bash
# shellcheck source=/dev/null
# Usage: ./bootstrap.sh
# This script will:
#   - install Mint and bootstrap its dependencies
#   - link git hooks
#   - install allure dependencies if `INSTALL_ALLURE` environment variable is provided
#   - install sonar-scanner if `INSTALL_SONAR` environment variable is provided
# If you get `zsh: permission denied: ./bootstrap.sh` error, please run `chmod +x bootstrap.sh` first

function puts {
  echo
  echo -e "👉 ${1}"
}

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

if [ "${SKIP_MINT_BOOTSTRAP:-}" != true ]; then
  puts "Bootstrap Mint dependencies"
  git clone https://github.com/yonaskolb/Mint.git fastlane/mint
  root=$(pwd)
  cd fastlane/mint
  swift run mint install "yonaskolb/mint@${MINT_VERSION}"
  cd $root
  rm -rf fastlane/mint
  mint bootstrap --link
fi

if [[ ${INSTALL_SONAR-default} == true ]]; then
  puts "Install sonar scanner"
  DOWNLOAD_URL="https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_VERSION}-macosx-x64.zip"
  curl -sL "${DOWNLOAD_URL}" -o ./fastlane/sonar.zip
  cd fastlane
  unzip sonar.zip
  rm sonar.zip
  cd ..
  mv "fastlane/sonar-scanner-${SONAR_VERSION}-macosx-x64/" fastlane/sonar/
  chmod +x ./fastlane/sonar/bin/sonar-scanner
fi

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

if [[ ${INSTALL_YEETD-default} == true ]]; then
  PACKAGE="yeetd-normal.pkg"
  puts "Install yeetd v${YEETD_VERSION}"
  wget "https://github.com/biscuitehh/yeetd/releases/download/${YEETD_VERSION}/${PACKAGE}"
  sudo installer -pkg ${PACKAGE} -target /
  puts "Running yeetd daemon"
  yeetd &
fi

if [[ ${INSTALL_GCLOUD-default} == true ]]; then
  puts "Install gcloud"
  brew install --cask google-cloud-sdk

  # Editor access required: https://console.cloud.google.com/iam-admin/iam
  printf "%s" "$GOOGLE_APPLICATION_CREDENTIALS" > ./fastlane/gcloud-service-account-key.json
  gcloud auth activate-service-account --key-file="./fastlane/gcloud-service-account-key.json"
  gcloud config set project stream-chat-swift
  gcloud services enable toolresults.googleapis.com
fi