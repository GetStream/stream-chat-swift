Guidance for AI coding agents (Copilot, Cursor, Aider, Claude, etc.) working in this repository. Human readers are welcome, but this file is written for tools.

### Repository purpose

This repo hosts Stream’s iOS Chat SDK in Swift. It provides:
  • A low-level client (StreamChat) for the Stream Chat API
  • UI SDK (StreamChatUI) that provides chat screens/components

Agents should prioritize backwards compatibility, API stability, and high test coverage when changing code.

### Tech & toolchain
  • Language: Swift (iOS; Mac Catalyst supported)
  • Package managers: Swift Package Manager (primary) and XCFrameworks (also supported)
  • Minimum Xcode: 15.x or newer (Apple Silicon supported)
  • iOS targets: Follow existing deployment targets in package file; don’t lower without approval
  • CI: GitHub Actions (assume PR validation on build + tests + lint)
  • Linters & docs: SwiftLint and SwiftFormat

### Project layout (high level)

Sources/
  StreamChat/            # Core chat client, models, networking, state
  StreamChatUI/          # UIKit components
Tests/
  StreamChatTests/
  StreamChatUITests/

Use the closest folder’s patterns and conventions when editing.

### Local setup (SPM)
  1.  Open the repository root in Xcode (Package.swift is present), resolve packages.
  2.  Select the intended scheme (see Schemes below), pick an iOS Simulator (e.g., iPhone 15), then Build.

### Schemes

Common scheme names in this repo include (exact names may evolve):
  • StreamChat
  • StreamChatUI
  • Corresponding …Tests schemes

Agents should query existing schemes from the project before invoking xcodebuild.

### Build & test commands (CLI)

Prefer Xcode for day-to-day work; use CLI for CI parity & agent automation.

Swift Package (workspace-based) build:

```
xcodebuild \
  -scheme StreamChat \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -configuration Debug build
```

Run unit tests for all modules:

```
xcodebuild \
  -scheme StreamChat \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -configuration Debug test
```

```
xcodebuild \
  -scheme StreamChatUI \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -configuration Debug test
```

If a Makefile is present, prefer the provided targets (e.g., make build, make test, make format, make lint). Always run make help to discover tasks.

Linting & formatting
  • SwiftLint is part of onboarding and may be installed via Mint. Run before committing:

```
swiftlint --strict
```

  • Respect .swiftlint.yml and any repo-specific rules. Do not suppress rules broadly; justify and scope exceptions.

Commit / PR conventions
  • Update CHANGELOG entries for user-visible SDK changes.
  • Keep PRs small and focused; include tests.
  • Follow the project’s “zero warnings” policy—fix new warnings and avoid introducing any.
  • For UI changes, attach comparison screenshots (before/after) where feasible.
  • Ensure public API changes include docs and migration notes.

Testing policy
  • Add/extend tests in the matching module’s Tests/ folder.
  • Cover:
    • Core models & API surface (StreamChat)
    • View Controllers and UI behaviors (StreamChatUI)
    • Use fakes/mocks from the test helpers provided by the repo when possible.

Docs & samples
  • When altering public API, update inline docs and any affected guide pages in the docs site where this repo is the source of truth.
  • Keep sample/snippet code compilable; prefer // MARK: sections and concise examples.

Security & credentials
  • Never commit API keys or customer data.
  • Example code must use obvious placeholders (e.g., YOUR_STREAM_KEY).
  • If you add scripts, ensure they fail closed on missing env vars.

Compatibility & distribution
  • Maintain compatibility with supported iOS versions listed in Package.swift.
  • Don’t introduce third-party deps without discussion.
  • Validate SPM integration when changing module boundaries.

When in doubt
  • Mirror existing patterns in the nearest module.
  • Prefer additive changes; avoid breaking public APIs.
  • Ask maintainers (CODEOWNERS) through PR mentions for modules you touch.

⸻

Quick agent checklist (per commit)
  • Build all modified modules for iOS Simulator
  • Run tests for affected modules and ensure green
  • Run swiftlint --strict
  • Update CHANGELOG and docs if public API changed
  • Add/adjust tests
  • No new warnings

End of machine guidance. Edit this file to refine agent behavior over time; keep human-facing details in README.md and docs.