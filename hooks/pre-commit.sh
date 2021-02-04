#!/bin/bash
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'Sources/*.swift'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'Tests/*.swift'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'Sample/*.swift'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'DemoApp/*.swift'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'Integration/*.swift'

# Regenerage Package.swift files if needed
./hooks/regenerage-spm-package-if-needed.sh
