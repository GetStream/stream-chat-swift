#!/bin/bash

./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'Sources/*.swift' '!*Generated*' '!*StreamSwiftyMarkdown*' '!*StreamDifferenceKit*' '!*StreamNuke*' '!*StreamSwiftyGif*'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'Tests/*.swift'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'StreamChatSample/*.swift'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'DemoApp/*.swift'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'Examples/*.swift'
./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'Integration/*.swift'
