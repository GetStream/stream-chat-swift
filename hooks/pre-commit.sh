#!/bin/bash

./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'Sources/*.swift' '!*Generated*'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'Tests/*.swift'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'Sample/*.swift'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'DemoApp/*.swift'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'SlackClone/*.swift'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'iMessageClone/*.swift'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'MessengerClone/*.swift'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'YouTubeClone/*.swift'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'Integration/*.swift'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat-snippets stdin' 'DocsSnippets/*.swift'

# Regenerage Package.swift files if needed
./hooks/regenerage-spm-package-if-needed.sh
