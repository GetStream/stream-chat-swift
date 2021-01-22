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
or alternatively using `brew install fastlane`

# Available Actions
### match_me
```
fastlane match_me
```
Installs all Certs and Profiles necessary for development and ad-hoc
### distribute_demo_app
```
fastlane distribute_demo_app
```
Builds the latest version of Demo app and uploads it to Firebase
### get_next_issue_number
```
fastlane get_next_issue_number
```
Get next PR number from github to be used in CHANGELOG
### test
```
fastlane test
```
Runs tests in Debug config
### test_release
```
fastlane test_release
```
Runs tests in Release config
### stress_test
```
fastlane stress_test
```
Runs stress tests for
### stress_test_release
```
fastlane stress_test_release
```
Runs stress tests for v3 in Release config
### build_sample
```
fastlane build_sample
```
Builds v3 Sample app

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
