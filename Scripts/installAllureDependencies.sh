#!/usr/bin/env bash

function puts {
  echo
  echo -e "👉 ${1}"
}

ALLURECTL_REPO='https://github.com/allure-framework/allurectl'
ALLURECTL_VERSION='1.22.1'
puts "Install allurectl v${ALLURECTL_VERSION}"
curl -sL "${ALLURECTL_REPO}/releases/download/${ALLURECTL_VERSION}/allurectl_darwin_amd64" -o ./fastlane/allurectl
chmod +x ./fastlane/allurectl

XCRESULTS_REPO='https://github.com/eroshenkoam/xcresults'
XCRESULTS_VERSION='1.10.1'
puts "Install xcresults v${XCRESULTS_VERSION}"
curl -sL "${XCRESULTS_REPO}/releases/download/${XCRESULTS_VERSION}/xcresults" -o ./fastlane/xcresults
chmod +x ./fastlane/xcresults
