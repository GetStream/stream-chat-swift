fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### sonar_upload

```sh
[bundle exec] fastlane sonar_upload
```

Get code coverage report and run complexity analysis for Sonar

### allure_upload

```sh
[bundle exec] fastlane allure_upload
```

Upload test results to Allure TestOps

### allure_launch

```sh
[bundle exec] fastlane allure_launch
```

Create launch on Allure TestOps

### allure_create_testcase

```sh
[bundle exec] fastlane allure_create_testcase
```

Create test-case in Allure TestOps and get its id

### allure_start_regression

```sh
[bundle exec] fastlane allure_start_regression
```

Sync and run regression test-plan on Allure TestOps

### build_xcframeworks

```sh
[bundle exec] fastlane build_xcframeworks
```

Build .xcframeworks

### release

```sh
[bundle exec] fastlane release
```

Start a new release

### publish_release

```sh
[bundle exec] fastlane publish_release
```

Completes an SDK Release

### push_pods

```sh
[bundle exec] fastlane push_pods
```

Pushes the StreamChat and StreamChatUI SDK podspecs to Cocoapods trunk

### set_SDK_version

```sh
[bundle exec] fastlane set_SDK_version
```



### match_me

```sh
[bundle exec] fastlane match_me
```

If `readonly: true` (by default), installs all Certs and Profiles necessary for development and ad-hoc.
If `readonly: false`, recreates all Profiles necessary for development and ad-hoc, updates them locally and remotely.

### register_new_device_and_recreate_profiles

```sh
[bundle exec] fastlane register_new_device_and_recreate_profiles
```

Register new device, regenerates profiles, updates them remotely and locally

### distribute_demo_app

```sh
[bundle exec] fastlane distribute_demo_app
```

Builds the latest version of Demo app and uploads it to Firebase

### testflight_build

```sh
[bundle exec] fastlane testflight_build
```

Builds the latest version of Demo app and uploads it to TestFlight

### get_next_issue_number

```sh
[bundle exec] fastlane get_next_issue_number
```

Get next PR number from github to be used in CHANGELOG

### test

```sh
[bundle exec] fastlane test
```

Runs tests in Debug config

### test_e2e_mock

```sh
[bundle exec] fastlane test_e2e_mock
```

Runs e2e ui tests using mock server in Debug config

### test_ui

```sh
[bundle exec] fastlane test_ui
```

Runs ui tests in Debug config

### test_ui_release

```sh
[bundle exec] fastlane test_ui_release
```

Runs ui tests in Release config

### test_release

```sh
[bundle exec] fastlane test_release
```

Runs tests in Release config

### test_release_macos

```sh
[bundle exec] fastlane test_release_macos
```

Runs tests in Release config on macOS

### test_debug_macos

```sh
[bundle exec] fastlane test_debug_macos
```

Runs tests in Debug config on macOS

### stress_test

```sh
[bundle exec] fastlane stress_test
```

Runs stress tests for Debug config

### stress_test_release

```sh
[bundle exec] fastlane stress_test_release
```

Runs stress tests in Release config

### build_sample

```sh
[bundle exec] fastlane build_sample
```

Builds Sample app

### build_demo

```sh
[bundle exec] fastlane build_demo
```

Builds Demo app

### build_imessage_clone

```sh
[bundle exec] fastlane build_imessage_clone
```

Builds iMessageClone app

### build_slack_clone

```sh
[bundle exec] fastlane build_slack_clone
```

Builds SlackClone app

### build_messenger_clone

```sh
[bundle exec] fastlane build_messenger_clone
```

Builds MessengerClone app

### build_youtube_clone

```sh
[bundle exec] fastlane build_youtube_clone
```

Builds YouTubeClone app

### build_docs_snippets

```sh
[bundle exec] fastlane build_docs_snippets
```

Build Docs Snippets target

### spm_integration

```sh
[bundle exec] fastlane spm_integration
```

Test SPM Integration

### cocoapods_integration

```sh
[bundle exec] fastlane cocoapods_integration
```

Test CocoaPods Integration

### emerge_upload

```sh
[bundle exec] fastlane emerge_upload
```

Build and upload DemoApp to Emerge

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
