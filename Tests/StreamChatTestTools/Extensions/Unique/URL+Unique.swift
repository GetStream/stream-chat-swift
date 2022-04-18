//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public extension URL {
    /// Returns a unique random URL
    static func unique() -> URL {
        URL(string: "test://temporary_\(UUID().uuidString)")!
    }

    /// Returns a unique URL that can be used for storing a temporary file.
    static func newTemporaryFileURL() -> URL {
        newTemporaryDirectoryURL().appendingPathComponent("temp_file")
    }

    /// Creates a new temporary directory and returns its URL.
    static func newTemporaryDirectoryURL() -> URL {
        let directoryId = UUID().uuidString
        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let newDirURL = tempDirectoryURL.appendingPathComponent(directoryId)
        try! FileManager.default.createDirectory(at: newDirURL, withIntermediateDirectories: true, attributes: nil)
        return newDirURL
    }
}
