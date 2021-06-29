#!/bin/bash

pushd docusaurus/docs/iOS/common-content/reference-docs

find . -name "*.md" ! -name '*-properties.md' -type f -exec sh -c 'N="${0%.*}-properties.md"; awk "/## Properties/{p=1}p" {} | awk "NR>2 {print last} {last=\$0}" > $N' {} \;

popd
