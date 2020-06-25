#!/bin/bash
./hooks/git-format-staged --formatter "swiftformat --config .swiftformat stdin" "StreamChatClient_v3/**/*.swift"
./hooks/git-format-staged --formatter "swiftformat --config .swiftformat stdin" "TestResources_v3/**/*.swift"
