#!/usr/bin/env bash
set -euo pipefail

echo -e "👉 Running SwiftFormat Linting"

echo -e "👉 Linting Sources..."
mint run swiftformat --lint --config .swiftformat Sources --exclude **/Generated,Sources/StreamChatUI/StreamNuke,Sources/StreamChatUI/StreamSwiftyGif,Sources/StreamChatUI/StreamSwiftyMarkdown,Sources/StreamChatUI/StreamDifferenceKit

echo -e "👉 Linting Tests..."
mint run swiftformat --lint --config .swiftformat Tests

echo -e "👉 Linting DemoApp..."
mint run swiftformat --lint --config .swiftformat DemoApp

echo -e "👉 Linting Integration..."
mint run swiftformat --lint --config .swiftformat Integration
