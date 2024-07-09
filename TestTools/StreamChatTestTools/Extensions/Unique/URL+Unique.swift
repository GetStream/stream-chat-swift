//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public extension URL {
    /// Returns a unique random URL
    static func unique() -> URL {
        URL(string: "test://temporary_\(UUID().uuidString)")!
    }

    /// Returns a unique URL that can be used for storing a temporary file.
    static func newTemporaryFileURL() -> URL {
        newTemporaryDirectoryURL().appendingPathComponent(temporaryFileName)
    }

    /// Creates a new temporary directory and returns its URL.
    static func newTemporaryDirectoryURL() -> URL {
        let directoryId = UUID().uuidString
        let newDirURL = URL.temporaryDirectoryRoot.appendingPathComponent(directoryId)
        try! FileManager.default.createDirectory(at: newDirURL, withIntermediateDirectories: true, attributes: nil)
        return newDirURL
    }
}

extension URL {
    static var temporaryDirectoryRoot: URL {
        try! FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appendingPathComponent("StreamChatTests")
    }
    
    static let temporaryFileName = "temp_file"
}
