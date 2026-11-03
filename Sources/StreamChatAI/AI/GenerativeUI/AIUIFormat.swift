//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The language a reply's generated UI is written in, such as OpenUI. It is an open set: each
/// renderer says which one it reads.
public struct AIUIFormat: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { rawValue = value }
    public var description: String { rawValue }

    /// [OpenUI](https://github.com/thesysdev/openui) Lang, a compact program.
    public static let openUI: AIUIFormat = "openui"
    /// [A2UI](https://a2ui.org), JSON messages that build surfaces.
    public static let a2ui: AIUIFormat = "a2ui"
}
