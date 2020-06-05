fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
### release
```
fastlane release
```
Release a new version
### match_me
```
fastlane match_me
```
Installs all Certs and Profiles necessary for development and ad-hoc
### beta
```
fastlane beta
```
Builds the latest version with ad-hoc and uploads to firebase
### carthage_bootstrap
```
fastlane carthage_bootstrap
```
Installs Carthage dependencies necessary for development (and building Carthage Example)
### build_for_testing
```
fastlane build_for_testing
```
Builds the project for testing
### test_without_building
```
fastlane test_without_building
```
Runs all the tests without building
### test_backend_integration
```
fastlane test_backend_integration
```
Runs integrations tests with backend. These tests make network connections so they're sometimes not reliable, hence we run them up to 3 times in case of failure
### test_integrations
```
fastlane test_integrations
```
Tests SDK integrations with Carthage, Cocoapods and SPM
### test_carthage_integration
```
fastlane test_carthage_integration
```
Tests integration with Carthage by building Carthage Example
### test_cocoapods_integration
```
fastlane test_cocoapods_integration
```
Tests integration with Cocoapods by building Cocoapods Example
### test_spm_integration
```
fastlane test_spm_integration
```
Tests integration with SPM by building SPM Example
### get_next_issue_number
```
fastlane get_next_issue_number
```
Get next PR number from github to be used in CHANGELOG
### test_v3
```
fastlane test_v3
```
Runs tests for v3 scheme

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
