#!/bin/bash
git diff --diff-filter=d --staged --name-only -- StreamChatClient_v3 | grep -e '\.swift$' | while read file; do
  swiftformat "${file}";
  git add "$file";
done