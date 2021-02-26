#!/bin/bash
# Regenerate list of files in Package.swift
arch -x86_64 ./generateSPMFileLists

# Add changes to the current commit 
git add Package.swift