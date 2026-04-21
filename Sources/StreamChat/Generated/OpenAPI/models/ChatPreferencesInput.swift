//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChatPreferencesInput: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum ChatPreferencesInputChannelMentions: String, Sendable, Codable, CaseIterable {
        case all
        case none
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    enum ChatPreferencesInputDefaultPreference: String, Sendable, Codable, CaseIterable {
        case all
        case none
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    enum ChatPreferencesInputDirectMentions: String, Sendable, Codable, CaseIterable {
        case all
        case none
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    enum ChatPreferencesInputGroupMentions: String, Sendable, Codable, CaseIterable {
        case all
        case none
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    enum ChatPreferencesInputHereMentions: String, Sendable, Codable, CaseIterable {
        case all
        case none
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    enum ChatPreferencesInputRoleMentions: String, Sendable, Codable, CaseIterable {
        case all
        case none
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    enum ChatPreferencesInputThreadReplies: String, Sendable, Codable, CaseIterable {
        case all
        case none
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

    var channelMentions: ChatPreferencesInputChannelMentions?
    var defaultPreference: ChatPreferencesInputDefaultPreference?
    var directMentions: ChatPreferencesInputDirectMentions?
    var groupMentions: ChatPreferencesInputGroupMentions?
    var hereMentions: ChatPreferencesInputHereMentions?
    var roleMentions: ChatPreferencesInputRoleMentions?
    var threadReplies: ChatPreferencesInputThreadReplies?

    init(channelMentions: ChatPreferencesInputChannelMentions? = nil, defaultPreference: ChatPreferencesInputDefaultPreference? = nil, directMentions: ChatPreferencesInputDirectMentions? = nil, groupMentions: ChatPreferencesInputGroupMentions? = nil, hereMentions: ChatPreferencesInputHereMentions? = nil, roleMentions: ChatPreferencesInputRoleMentions? = nil, threadReplies: ChatPreferencesInputThreadReplies? = nil) {
        self.channelMentions = channelMentions
        self.defaultPreference = defaultPreference
        self.directMentions = directMentions
        self.groupMentions = groupMentions
        self.hereMentions = hereMentions
        self.roleMentions = roleMentions
        self.threadReplies = threadReplies
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelMentions = "channel_mentions"
        case defaultPreference = "default_preference"
        case directMentions = "direct_mentions"
        case groupMentions = "group_mentions"
        case hereMentions = "here_mentions"
        case roleMentions = "role_mentions"
        case threadReplies = "thread_replies"
    }

    static func == (lhs: ChatPreferencesInput, rhs: ChatPreferencesInput) -> Bool {
        lhs.channelMentions == rhs.channelMentions &&
            lhs.defaultPreference == rhs.defaultPreference &&
            lhs.directMentions == rhs.directMentions &&
            lhs.groupMentions == rhs.groupMentions &&
            lhs.hereMentions == rhs.hereMentions &&
            lhs.roleMentions == rhs.roleMentions &&
            lhs.threadReplies == rhs.threadReplies
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelMentions)
        hasher.combine(defaultPreference)
        hasher.combine(directMentions)
        hasher.combine(groupMentions)
        hasher.combine(hereMentions)
        hasher.combine(roleMentions)
        hasher.combine(threadReplies)
    }
}
