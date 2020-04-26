//
//  Channel+Config.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 14/04/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: Config

public extension Channel {
    /// A channel config.
    struct Config: Decodable {
        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case reactionsEnabled = "reactions"
            case typingEventsEnabled = "typing_events"
            case readEventsEnabled = "read_events"
            case connectEventsEnabled = "connect_events"
            case uploadsEnabled = "uploads"
            case repliesEnabled = "replies"
            case searchEnabled = "search"
            case mutesEnabled = "mutes"
            case urlEnrichmentEnabled = "url_enrichment"
            case messageRetention = "message_retention"
            case maxMessageLength = "max_message_length"
            case commands
            case created = "created_at"
            case updated = "updated_at"
        }
        
        /// If users are allowed to add reactions to messages. Enabled by default.
        public let reactionsEnabled: Bool
        /// Controls if typing indicators are shown. Enabled by default.
        public let typingEventsEnabled: Bool
        /// Controls whether the chat shows how far you’ve read. Enabled by default.
        public let readEventsEnabled: Bool
        /// Determines if events are fired for connecting and disconnecting to a chat. Enabled by default.
        public let connectEventsEnabled: Bool
        /// Enables uploads.
        public let uploadsEnabled: Bool
        /// Enables message threads and replies. Enabled by default.
        public let repliesEnabled: Bool
        /// Controls if messages should be searchable (this is a premium feature). Disabled by default.
        public let searchEnabled: Bool
        /// Determines if users are able to mute other users. Enabled by default.
        public let mutesEnabled: Bool
        /// Determines if URL enrichment enabled to show they as attachments. Enabled by default.
        public let urlEnrichmentEnabled: Bool
        /// Determines if users are able to flag messages. Enabled by default.
        public let flagsEnabled: Bool
        /// A number of days or infinite. Infinite by default.
        public let messageRetention: String
        /// The max message length. 5000 by default.
        public let maxMessageLength: Int
        /// An array of commands, e.g. /giphy.
        public let commands: [Command]
        /// A channel created date.
        public let created: Date
        /// A channel updated date.
        public let updated: Date
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            reactionsEnabled = try container.decode(Bool.self, forKey: .reactionsEnabled)
            typingEventsEnabled = try container.decode(Bool.self, forKey: .typingEventsEnabled)
            readEventsEnabled = try container.decode(Bool.self, forKey: .readEventsEnabled)
            connectEventsEnabled = try container.decode(Bool.self, forKey: .connectEventsEnabled)
            uploadsEnabled = try container.decodeIfPresent(Bool.self, forKey: .uploadsEnabled) ?? false
            repliesEnabled = try container.decode(Bool.self, forKey: .repliesEnabled)
            searchEnabled = try container.decode(Bool.self, forKey: .searchEnabled)
            mutesEnabled = try container.decode(Bool.self, forKey: .mutesEnabled)
            urlEnrichmentEnabled = try container.decode(Bool.self, forKey: .urlEnrichmentEnabled)
            messageRetention = try container.decode(String.self, forKey: .messageRetention)
            maxMessageLength = try container.decode(Int.self, forKey: .maxMessageLength)
            commands = try container.decodeIfPresent([Command].self, forKey: .commands) ?? []
            flagsEnabled = commands.first(where: { $0.name.contains("flag") }) != nil
            created = try container.decode(Date.self, forKey: .created)
            updated = try container.decode(Date.self, forKey: .updated)
        }
        
        public init(reactionsEnabled: Bool = false,
                    typingEventsEnabled: Bool = false,
                    readEventsEnabled: Bool = false,
                    connectEventsEnabled: Bool = false,
                    uploadsEnabled: Bool = false,
                    repliesEnabled: Bool = false,
                    searchEnabled: Bool = false,
                    mutesEnabled: Bool = false,
                    urlEnrichmentEnabled: Bool = false,
                    flagsEnabled: Bool = false,
                    messageRetention: String = "",
                    maxMessageLength: Int = 0,
                    commands: [Command] = [],
                    created: Date = .init(),
                    updated: Date = .init()) {
            self.reactionsEnabled = reactionsEnabled
            self.typingEventsEnabled = typingEventsEnabled
            self.readEventsEnabled = readEventsEnabled
            self.connectEventsEnabled = connectEventsEnabled
            self.uploadsEnabled = uploadsEnabled
            self.repliesEnabled = repliesEnabled
            self.searchEnabled = searchEnabled
            self.mutesEnabled = mutesEnabled
            self.urlEnrichmentEnabled = urlEnrichmentEnabled
            self.flagsEnabled = flagsEnabled
            self.messageRetention = messageRetention
            self.maxMessageLength = maxMessageLength
            self.commands = commands
            self.created = created
            self.updated = updated
        }
    }
    
    /// A command in a message, e.g. /giphy.
    struct Command: Decodable, Hashable {
        /// A command name.
        public let name: String
        /// A description.
        public let description: String
        public let set: String
        /// Args for the command.
        public let args: String
        
        public init(name: String = "",
                    description: String = "",
                    set: String = "",
                    args: String = "") {
            self.name = name
            self.description = description
            self.set = set
            self.args = args
        }
        
        public static func == (lhs: Command, rhs: Command) -> Bool {
            lhs.name == rhs.name
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }
    }
}
