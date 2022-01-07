//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type that describes a message reaction type.
///
/// The reaction has underlaying type `String` what gives the flexibility to choose the way how the reaction
/// will be displayed in the application.
///
/// Common examples are: "like", "love", "smile", etc.
public struct MessageReactionType: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
    // MARK: - RawRepresentable
    
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    // MARK: - ExpressibleByStringLiteral
    
    public init(stringLiteral: String) {
        self.init(rawValue: stringLiteral)
    }
    
    // MARK: - Codable
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(
            rawValue: try container.decode(String.self)
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
