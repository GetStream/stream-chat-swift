//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// An enum describing possible types of a channel.
public enum ChannelType: Codable, Hashable {
    /// Sensible defaults in case you want to build livestream chat like Instagram Livestream or Periscope.
    case livestream
    
    /// Configured for apps such as WhatsApp or Facebook Messenger.
    case messaging
    
    /// If you want to build your own version of Slack or something similar, start here.
    case team
    
    /// Good defaults for building something like your own version of Twitch.
    case gaming
    
    /// Good defaults for building something like your own version of Intercom or Drift.
    case commerce
    
    /// The type of the channel is custom.
    case custom(String)
    
    /// A channel type title.
    public var title: String { rawValue.capitalized }
    
    /// A raw value of the channel type.
    public var rawValue: String {
        switch self {
        case .livestream: return "livestream"
        case .messaging: return "messaging"
        case .team: return "team"
        case .gaming: return "gaming"
        case .commerce: return "commerce"
        case let .custom(value): return value
        }
    }
    
    /// Init a channel type with a string raw value.
    ///
    /// - Parameter rawValue: a string raw value of a channel type.
    init(rawValue: String) {
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
