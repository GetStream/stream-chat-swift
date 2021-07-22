//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension URL {
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

extension String {
    /// Returns a new unique string
    static var unique: String { UUID().uuidString }
}

extension Token {
    /// Returns a new `Token` with the provided `user_id` but not in JWT format.
    static func unique(userId: UserId = .unique) -> Self {
        .init(rawValue: .unique, userId: userId, expiration: nil)
    }
}

extension AttachmentAction {
    /// Returns a new unique action
    static var unique: Self {
        .init(
            name: .unique,
            value: .unique,
            style: .primary,
            type: .button,
            text: .unique
        )
    }
}

extension AttachmentId {
    /// Returns a new unique id
    static var unique: Self {
        .init(cid: .unique, messageId: .unique, index: .random(in: 1..<1000))
    }
}

extension Date {
    /// Returns a new random date
    static var unique: Date { Date(timeIntervalSince1970: .random(in: 1_000_000...1_500_000_000)) }

    /// Returns a new random date before the provided date
    static func unique(before date: Date, after: Date = Date.distantPast) -> Date {
        Date(timeIntervalSince1970: .random(in: after.timeIntervalSince1970..<date.timeIntervalSince1970 - 1))
    }

    /// Returns a new random date after the provided date
    static func unique(after date: Date) -> Date {
        Date(timeIntervalSince1970: .random(in: (date.timeIntervalSince1970 + 1)...Date.distantFuture.timeIntervalSince1970))
    }
}

extension Int {
    static var unique: Int { .random(in: 1..<1000) }
}
