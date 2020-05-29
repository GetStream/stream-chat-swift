//
//  TemporaryURLs.swift
//  StreamChatClient_v3
//
//  Created by Vojta on 26/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension URL {
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
