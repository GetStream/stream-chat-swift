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
### build_xcframeworks
```
fastlane build_xcframeworks
```
Build .xcframeworks
### release
```
fastlane release
```
Release a new version
### complete_release
```
fastlane complete_release
```
Completes an SDK Release
### push_pods
```
fastlane push_pods
```
Pushes the StreamChat and StreamChatUI SDK podspecs to Cocoapods trunk
### set_SDK_version
```
fastlane set_SDK_version
```

### match_me
```
fastlane match_me
```
If `readonly: true` (by default), installs all Certs and Profiles necessary for development and ad-hoc.
If `readonly: false`, recreates all Profiles necessary for development and ad-hoc, updates them locally and remotely.
### register_new_device_and_recreate_profiles
```
fastlane register_new_device_and_recreate_profiles
```
Register new device, regenerates profiles, updates them remotely and locally
### distribute_demo_app
```
fastlane distribute_demo_app
```
Builds the latest version of Demo app and uploads it to Firebase
### testflight_build
```
fastlane testflight_build
```
Builds the latest version of Demo app and uploads it to TestFlight
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
### test_ui
```
fastlane test_ui
```
Runs ui tests in Debug config
### test_ui_release
```
fastlane test_ui_release
```
Runs ui tests in Release config
### test_release
```
fastlane test_release
```
Runs tests in Release config
### test_release_macos
```
fastlane test_release_macos
```
Runs tests in Release config on macOS
### test_debug_macos
```
fastlane test_debug_macos
```
Runs tests in Debug config on macOS
### stress_test
```
fastlane stress_test
```
Runs stress tests for Debug config
### stress_test_release
```
fastlane stress_test_release
```
Runs stress tests in Release config
### build_sample
```
fastlane build_sample
```
Builds Sample app
### build_demo
```
fastlane build_demo
```
Builds Demo app
### build_imessage_clone
```
fastlane build_imessage_clone
```
Builds iMessageClone app
### build_slack_clone
```
fastlane build_slack_clone
```
Builds SlackClone app
### build_messenger_clone
```
fastlane build_messenger_clone
```
Builds MessengerClone app
### build_youtube_clone
```
fastlane build_youtube_clone
```
Builds YouTubeClone app
### build_docs_snippets
```
fastlane build_docs_snippets
```
Build Docs Snippets target
### spm_integration
```
fastlane spm_integration
```
Test SPM Integration
### cocoapods_integration
```
fastlane cocoapods_integration
```
Test CocoaPods Integration
### emerge_upload
```
fastlane emerge_upload
```
Build and upload DemoApp to Emerge

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
