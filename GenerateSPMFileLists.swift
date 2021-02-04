#!/usr/bin/swift

//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

// This script is used to generate list of excluded source files for StreamChat and StreamChatUI in Package.swift.
// SPM currently doesn't support path expanding so we can't simply exlude files using placeholders like `*_Tests.swift`.

import Foundation

let generatedContentHeader = "// ** ⚠️ GENERATED, do not edit directly below this point **"

func sourceFileList(at url: URL) -> [String] {
    var allFiles = [URL]()
    let enumerator = FileManager.default.enumerator(
        at: url,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles, .skipsPackageDescendants]
    )!

    for case let fileURL as URL in enumerator {
        let fileAttributes = try! fileURL.resourceValues(forKeys: [.isRegularFileKey])
        if fileAttributes.isRegularFile! {
            allFiles.append(fileURL)
        }
    }

    let sourceFiles = allFiles
        .map(\.path)
        .map { path -> String in
            // Remove base part of the path
            let basePathRange = path.range(of: url.path + "/")!
            return String(path[basePathRange.upperBound...])
        }
        .filter { $0.hasSuffix("_Tests.swift") || $0.hasSuffix("_Mock.swift") }

    return sourceFiles
}

// Generate new content

var newGeneratedContent = generatedContentHeader + "\n\n"

// StreamChat excluded source files
let streamChatSources = sourceFileList(at: URL(string: "Sources/StreamChat")!)
newGeneratedContent += "var streamChatSourcesExcluded: [String] { [\n"
for (idx, source) in streamChatSources.enumerated() {
    newGeneratedContent += "    \"\(source)\""
    if idx == streamChatSources.endIndex - 1 {
        newGeneratedContent += "\n"
    } else {
        newGeneratedContent += ",\n"
    }
}

newGeneratedContent += "] }\n"

newGeneratedContent += "\n"

// StreamChatUI excluded source files
let streamChatUISources = sourceFileList(at: URL(string: "Sources/StreamChatUI")!)
newGeneratedContent += "var streamChatUISourcesExcluded: [String] { [\n"
for (idx, source) in streamChatUISources.enumerated() {
    newGeneratedContent += "    \"\(source)\""
    if idx == streamChatUISources.endIndex - 1 {
        newGeneratedContent += "\n"
    } else {
        newGeneratedContent += ",\n"
    }
}

newGeneratedContent += "] }\n"

// Load Package.swift
let packageFileURL = URL(fileURLWithPath: "Package.swift")
var packageFileContent = String(data: try! Data(contentsOf: packageFileURL), encoding: .utf8)!
let generatedPartRange = packageFileContent.range(of: generatedContentHeader)!
packageFileContent.removeSubrange(generatedPartRange.lowerBound...)
packageFileContent += newGeneratedContent

// Write the changes back
try! packageFileContent.write(to: packageFileURL, atomically: true, encoding: String.Encoding.utf8)
