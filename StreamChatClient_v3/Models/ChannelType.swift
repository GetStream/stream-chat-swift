//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A channel type.
public enum ChannelType: Codable, Hashable, ExpressibleByStringLiteral {
    /// A channel type.
    case unknown, livestream, messaging, team, gaming, commerce
    case custom(String)
    
    /// A channel type title.
    public var title: String { rawValue.capitalized }
    
    /// A raw value of the channel type.
    public var rawValue: String {
        switch self {
        case .unknown: return "unknown"
        case .livestream: return "livestream"
        case .messaging: return "messaging"
        case .team: return "team"
        case .gaming: return "gaming"
        case .commerce: return "commerce"
        case let .custom(value): return value
        }
    }
    
    /// Init a channel type with a string raw value.
    /// - Parameter rawValue: a string raw value of a channel type.
    public init(rawValue: String) {
        if rawValue.isEmpty || rawValue.contains(" ") || rawValue == "unknown" {
            self = .unknown
            return
        }
        
        switch rawValue {
        case "livestream": self = .livestream
        case "messaging": self = .messaging
        case "team": self = .team
        case "gaming": self = .gaming
        case "commerce": self = .commerce
        default: self = .custom(rawValue)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self.init(rawValue: value)
    }
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
