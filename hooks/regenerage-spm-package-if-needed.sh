#!/bin/bash

# Was there a new file added or deleted?
if [ ! -z "$(git diff --staged | grep  -e 'deleted\|new file mode')" ];
then
    # Regenerate list of files in Package.swift
    ./GenerateSPMFileLists.swift

    # Add changes to the current commit 
    git add Package.swift
fi
