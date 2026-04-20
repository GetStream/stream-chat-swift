Guidance for AI coding agents (Copilot, Cursor, Aider, Claude, etc.) working in this repository. Human readers are welcome, but this file is written for tools.

### Repository purpose

This repo hosts Stream's iOS Chat SDK in Swift. It provides:
- A low-level client (**StreamChat**) for the Stream Chat API — models, networking, state, persistence
- A UIKit-based UI SDK (**StreamChatUI**) that provides ready-made chat screens and components
- A shared UI module (**StreamChatCommonUI**) with appearance tokens, localization, and formatters used by both UIKit and SwiftUI SDKs

Agents should prioritize backwards compatibility, API stability, and high test coverage when changing code. Avoid doing any source-breaking changes without adding deprecations.

### Tech & toolchain

- Language: Swift 6.0 (strict concurrency enabled — `swift-tools-version:6.0`)
- Primary distribution: Swift Package Manager (SPM)
- Project file: `StreamChat.xcodeproj` (used for builds and tests; SPM manifest does not declare test targets)
- Xcode: 16.x or newer (Apple Silicon supported)
- Platforms / deployment targets: iOS 13+, macOS 11+ (see `Package.swift`; do not lower targets without approval)
- CI: GitHub Actions + Fastlane (see `.github/workflows/smoke-checks.yml`)
- Linting: SwiftLint (v0.59.1) — config in `.swiftlint.yml`
- Formatting: SwiftFormat (v0.58.2) — config in `.swiftformat`
- Code generation: SwiftGen (v6.5.1) — generates `L10n.swift` for localization strings
- Git hooks: lefthook (`lefthook.yml`) — runs SwiftLint fix + SwiftFormat on pre-commit, SwiftLint strict on pre-push
- Tool versions are pinned in `Githubfile`

### Dependencies

- **StreamCore** from [`stream-core-swift`](https://github.com/GetStream/stream-core-swift.git) (exact 0.6.2)
- **swift-docc-plugin** (exact 1.0.0) — for documentation generation
- **Vendored libraries** (do not edit directly):
  - `Sources/StreamChatUI/StreamNuke/` — vendored Nuke image loading
  - `Sources/StreamChatUI/StreamSwiftyGif/` — vendored SwiftyGif
  - `Sources/StreamChatUI/StreamDifferenceKit/` — vendored DifferenceKit for collection diffing
  - `Sources/StreamChat/StreamStarscream/` — vendored Starscream for WebSocket
  - Update these via `make update_nuke version=X.Y.Z` / `make update_swiftygif version=X.Y.Z` / `make update_differencekit version=X.Y.Z`

### Project layout (high level)

```
Sources/
  StreamChat/              # Core client: API, models, networking, state, persistence
    APIClient/             # REST API layer
    Audio/                 # Audio playback/recording utilities
    Config/                # SDK configuration
    Controllers/           # Channel, message, user controllers
    Database/              # Core Data persistence (DTOs, model, migrations)
    Extensions/            # Foundation/Swift extensions
    Generated/             # Auto-generated (version) — do not edit manually
    Models/                # Domain models (Channel, Message, User, etc.)
    Query/                 # Query types for filtering/sorting
    Repositories/          # Data repositories
    StateLayer/            # State observation layer
    StreamStarscream/      # Vendored — do not edit
    Utils/                 # Utilities, common helpers
    WebSocketClient/       # WebSocket connection management
    Workers/               # Background workers (event handling, sync)
  StreamChatUI/            # UIKit components: views, view controllers
    ChatChannel/           # Channel view & sub-components
    ChatChannelList/       # Channel list view controller
    ChatMessageList/       # Message list rendering
    ChatThread/            # Thread components
    ChatThreadList/        # Thread list
    CommonViews/           # Shared/reusable UIKit views
    Composer/              # Message composer
    Gallery/               # Media gallery
    MessageActionsPopup/   # Message action menus
    Navigation/            # Navigation routers
    Resources/             # UIKit-specific resources
    Utils/                 # UIKit utilities
    VoiceRecording/        # Voice recording components
    StreamNuke/            # Vendored — do not edit
    StreamSwiftyGif/       # Vendored — do not edit
    StreamDifferenceKit/   # Vendored — do not edit
  StreamChatCommonUI/      # Shared appearance, localization, formatters
    Appearance+*/          # Color palette, design tokens, fonts, images, formatters
    Generated/             # Auto-generated (L10n.swift) — do not edit manually
    Reactions/             # Reaction types and utilities
    Resources/             # Localization files (en.lproj, etc.)
    Utils/                 # Common UI utilities

DemoApp/                   # Primary demo app (use to validate UI changes)
DemoAppPush/               # Push notification extension for the demo
DemoShare/                 # Share extension for the demo
Examples/                  # Clone apps: iMessage, Slack, Messenger, YouTube, EdgeCases
Integration/               # SPM & CocoaPods integration samples
TestTools/
  StreamChatTestTools/     # Test mocks, fakes, fixtures, assertions
  StreamChatTestMockServer/ # Mock server for E2E tests
Tests/
  StreamChatTests/         # Unit tests for StreamChat (mirrors source structure)
  StreamChatUITests/       # Snapshot & unit tests for StreamChatUI
  StreamChatCommonUITests/ # Tests for StreamChatCommonUI
StreamChatUITestsApp/      # Test harness app for E2E tests
StreamChatUITestsAppUITests/ # E2E / UI automation tests
Scripts/                   # Helper scripts (bootstrap, dependency updates)
fastlane/                  # Fastlane lanes for CI (build, test, release)
Documentation.docc         # DocC documentation catalog
```

### New files & target membership

When creating new source or resource files, add them to the correct Xcode target(s). Update the project (e.g. `project.pbxproj`) so each new file is included in the appropriate target's "Compile Sources" (or "Copy Bundle Resources" for assets). Match the target(s) used by sibling files in the same directory (e.g. `Sources/StreamChat/` → StreamChat target; `Sources/StreamChatUI/` → StreamChatUI; `Sources/StreamChatCommonUI/` → StreamChatCommonUI; `Tests/StreamChatTests/` → StreamChatTests target). Omitting target membership will cause build failures or unused files.

### Local setup (SPM)

1. Open the repository in Xcode (root contains `Package.swift` and `StreamChat.xcodeproj`).
2. Resolve packages.
3. Choose an iOS Simulator (e.g., iPhone 17 Pro) and Build.

Optional: run `Scripts/bootstrap.sh` to install pinned versions of SwiftLint, SwiftFormat, and SwiftGen, and to set up lefthook git hooks.

### Demo app

The `DemoApp` target is a fully functional sample app. Prefer running it to validate UI changes. Keep demo configs free of credentials and use placeholders like `YOUR_STREAM_KEY`.

### Schemes

Available shared schemes (under `StreamChat.xcodeproj/xcshareddata/xcschemes/`):
  - `StreamChat` — builds the core framework
  - `StreamChatUI` — builds the UIKit framework
  - `StreamChatCommonUI` — builds the shared UI framework
  - `StreamChatTests` — runs core unit tests
  - `StreamChatTestToolsTests` — runs test tools tests
  - `DemoApp` — builds and runs the demo app
  - `StreamChatUITestsApp` — builds and runs the E2E test harness
  - `StreamChatUITestsAppUITests` — runs E2E / UI automation tests
  - `iMessage`, `Slack`, `Messenger`, `YouTube` — example/clone apps

Agents must query existing schemes before invoking xcodebuild.

### Build & test commands (CLI)

Prefer Xcode for day-to-day work; use CLI for CI parity & automation.

Build (Debug):

```
xcodebuild \
  -project StreamChat.xcodeproj \
  -scheme StreamChat \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build
```

Run tests:

```
xcodebuild \
  -project StreamChat.xcodeproj \
  -scheme StreamChatTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug test
```

```
xcodebuild \
  -project StreamChat.xcodeproj \
  -scheme StreamChatUI \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug test
```

If the device is not available, use one of the active booted devices, like so:

```
xcodebuild \
  -project StreamChat.xcodeproj \
  -scheme StreamChatTests \
  -destination "platform=iOS Simulator,OS=any,name=$(xcrun simctl list devices booted | grep '(Booted)' | head -1 | sed 's/ (.*)//')" \
  -configuration Debug test
```

### Linting & formatting

SwiftLint (strict mode):

```
swiftlint lint --config .swiftlint.yml --strict
```

SwiftFormat (check only — no edits):

```
swiftformat --config .swiftformat --lint .
```

SwiftFormat (auto-fix):

```
swiftformat --config .swiftformat .
```

Respect `.swiftlint.yml` and `.swiftformat` rules. Do not broadly disable rules; scope exceptions and justify in PRs.

### CI overview

CI is driven by Fastlane (see `fastlane/Fastfile`). Key lanes:

- `test` — runs StreamChat unit tests
- `test_ui` — runs StreamChatUI snapshot/unit tests
- `test_common_ui` — runs StreamChatCommonUI tests
- `test_e2e_mock` — runs E2E tests against a mock server
- `build_demo` — builds the demo app
- `build_test_app_and_frameworks` — builds test app and SDK frameworks
- `build_imessage_clone`, `build_slack_clone`, `build_messenger_clone`, `build_youtube_clone` — builds example apps
- `spm_integration` — validates SPM integration
- `run_swift_format` — runs SwiftFormat validation
- `validate_public_interface` — checks for unintended public API changes

The `smoke-checks.yml` workflow is the primary PR gate. It runs linting, formatting validation, public interface checks, unit tests, E2E tests, demo app builds, and example app builds.

### Generated code

Do not manually edit files in `Sources/StreamChat/Generated/`:
- `SystemEnvironment+Version.swift` — updated automatically during releases.

Do not manually edit files in `Sources/StreamChatCommonUI/Generated/`:
- `L10n.swift` — generated by SwiftGen from localization `.strings` files. Edit the `.strings` source files instead.
- `L10n_template.stencil` — the SwiftGen template for localization generation.

### Localization

The SDK uses `defaultLocalization: "en"`. String resources live in `Sources/StreamChatCommonUI/Resources/`. After modifying `.strings` files, regenerate `L10n.swift` by running SwiftGen (or let CI handle it). Always use `L10n` accessors for user-facing strings rather than raw string literals.

### Concurrency model

The project uses Swift 6.0 strict concurrency. When adding new code:
- Use `Sendable` conformances where needed for cross-isolation transfers
- Avoid introducing data races; the compiler will enforce actor isolation
- Mark UI-bound types and controllers appropriately for `@MainActor` when necessary

### Development guidelines

Accessibility & UI quality

- Ensure UIKit components have accessibility labels, traits, and dynamic type support.
- Support both light/dark mode.
- Use the Appearance system (`Appearance`, `Components`) for theming and configuration.

Testing policy

- Add/extend tests in the matching module's `Tests/` folder (mirrors the source directory structure):
  - `Tests/StreamChatTests/` for core client tests
  - `Tests/StreamChatUITests/` for UIKit component tests (including snapshot tests)
  - `Tests/StreamChatCommonUITests/` for shared UI module tests
- Test infrastructure (mocks, shared helpers, fixtures) lives in `TestTools/StreamChatTestTools/`
- Use fakes/mocks from the test helpers provided by the repo when possible.

Database conventions

- Core Data model lives in `Sources/StreamChat/Database/StreamChatModel.xcdatamodeld`
- In database DTOs under `Sources/StreamChat/Database/DTOs/`, use `DBDate` instead of `Date`/`NSDate` for NSManaged properties (enforced by SwiftLint custom rule)
- Prefer `.pin()` over `.constraint()` in `Sources/StreamChatUI/` for Auto Layout (enforced by SwiftLint custom rule)

Security & credentials

- Never commit API keys or customer data.
- Example code must use obvious placeholders (e.g., `YOUR_STREAM_KEY`).
- If you add scripts, ensure they fail closed on missing env vars.

Compatibility & distribution

- Maintain compatibility with supported iOS versions listed in `Package.swift`.
- Don't introduce third-party deps without discussion.
- Validate SPM integration when changing module boundaries.

### Branching & changelog

- The default integration branch is `develop`. Feature branches are merged into `develop`.
- Update `CHANGELOG.md` under the `# Upcoming` section when making client-facing changes (follow the Keep a Changelog format with `### Added`, `### Fixed`, `### Changed` subsections).
- The changelog has separate subsections for **StreamChat**, **StreamChatUI**, and **StreamChatCommonUI**.

### Pull Requests

- Use the Github CLI to create a PR and use the Linear MCP to link the relevant issue assigned to me.
- When creating a PR, the base branch should be the `develop` branch.
- Make sure that the PR respects the PR template in `.github/PULL_REQUEST_TEMPLATE.md`.
- Make sure to fill the template with atomic information, do not mention things that were done and then reverted in this same PR.
- Do not write "Made with Cursor" in the PR description.
