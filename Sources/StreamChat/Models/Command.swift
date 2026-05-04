//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A command in a message, e.g. /giphy.
public struct Command: Codable, Hashable, Sendable {
    /// A command name.
    public let name: String
    /// A description.
    public let description: String
    public let set: String
    /// Args for the command.
    public let args: String

    public init(name: String = "", description: String = "", set: String = "", args: String = "") {
        self.name = name
        self.description = description
        self.set = set
        self.args = args
    }
}
