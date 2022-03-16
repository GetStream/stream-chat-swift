//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    
    // some admin announcements to the app users
    case announcement

    // private channel in which user can join with password
    case privateMessaging

    // donation group
    case dao

    /// Good defaults for building something like your own version of Intercom or Drift.
    case commerce
    
    /// The type of the channel is custom.
    ///
    /// Only small letters, underscore and numbers should be used
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
        case .announcement: return "announcement"
        case .privateMessaging: return "privateMessaging"
        case .dao: return "dao"
        case .commerce: return "commerce"
        case let .custom(value):
            Self.assertCustomTypeValue(value)
            return value
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
        case "announcement": self = .announcement
        case "privateMessaging": self = .privateMessaging
        case "commerce": self = .commerce
        case "dao": self = .dao
        default:
            Self.assertCustomTypeValue(rawValue)
            self = .custom(rawValue)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self.init(rawValue: value)
        
        if case let .custom(value) = self {
            Self.assertCustomTypeValue(value)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
    
    /// Check that custom types have valid `rawValue`
    private static func assertCustomTypeValue(_ value: String) {
        let allowedCharacters = CharacterSet.lowercaseLetters
            .union(CharacterSet.uppercaseLetters)
            .union(CharacterSet(charactersIn: "0123456789_-"))
        let valueCharacters = CharacterSet(charactersIn: value)
        log.assert(
            valueCharacters.isSubset(of: allowedCharacters),
            // swiftlint:disable:next line_length
            "Value \"\(value)\" is not valid `ChannelType.custom` identifier, allowed characters are small letters, numbers and underscore."
        )
    }
}
