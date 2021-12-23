#!/usr/bin/env bash
set -euo pipefail

echo -e "👉 Running SwiftFormat Linting"

echo -e "👉 Linting Sources..."
mint run swiftformat --lint --config .swiftformat Sources --exclude **/Generated,Sources/StreamChat/StreamStarscream,Sources/StreamChat/StreamULID,Sources/StreamChatUI/StreamNuke,Sources/StreamChatUI/StreamSwiftyGif
echo -e "👉 Linting Tests..."
mint run swiftformat --lint --config .swiftformat Tests
echo -e "👉 Linting Sample..."
mint run swiftformat --lint --config .swiftformat StreamChatSample
echo -e "👉 Linting DemoApp..."
mint run swiftformat --lint --config .swiftformat DemoApp
echo -e "👉 Linting Integration..."
mint run swiftformat --lint --config .swiftformat Integration
echo -e "👉 Linting DocsSnippets..."
mint run swiftformat --lint --config .swiftformat-snippets DocsSnippets
