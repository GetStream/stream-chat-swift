//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A channel config.
public class ChannelConfig: Codable {
    private enum CodingKeys: String, CodingKey {
        case reactionsEnabled = "reactions"
        case typingEventsEnabled = "typing_events"
        case readEventsEnabled = "read_events"
        case connectEventsEnabled = "connect_events"
        case uploadsEnabled = "uploads"
        case repliesEnabled = "replies"
        case quotesEnabled = "quotes"
        case searchEnabled = "search"
        case mutesEnabled = "mutes"
        case urlEnrichmentEnabled = "url_enrichment"
        case messageRetention = "message_retention"
        case maxMessageLength = "max_message_length"
        case commands
        case createdAt = "created_at"
        case updatedAt = "updated_at"
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
    /// Enables message thread replies. Enabled by default.
    public let repliesEnabled: Bool
    /// Enables quoting of messages. Enabled by default.
    public let quotesEnabled: Bool
    /// Controls if messages should be searchable (this is a premium feature). Disabled by default.
    public let searchEnabled: Bool
    /// Determines if users are able to mute other users. Enabled by default.
    public let mutesEnabled: Bool
    /// Determines if URL enrichment enabled to show they as attachments. Enabled by default.
    public let urlEnrichmentEnabled: Bool
    /// A number of days or infinite. Infinite by default.
    public let messageRetention: String
    /// The max message length. 5000 by default.
    public let maxMessageLength: Int
    /// An array of commands, e.g. /giphy.
    public let commands: [Command]
    /// A channel created date.
    public let createdAt: Date
    /// A channel updated date.
    public let updatedAt: Date

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reactionsEnabled = try container.decode(Bool.self, forKey: .reactionsEnabled)
        typingEventsEnabled = try container.decode(Bool.self, forKey: .typingEventsEnabled)
        readEventsEnabled = try container.decode(Bool.self, forKey: .readEventsEnabled)
        connectEventsEnabled = try container.decode(Bool.self, forKey: .connectEventsEnabled)
        uploadsEnabled = try container.decodeIfPresent(Bool.self, forKey: .uploadsEnabled) ?? false
        repliesEnabled = try container.decode(Bool.self, forKey: .repliesEnabled)
        quotesEnabled = try container.decode(Bool.self, forKey: .quotesEnabled)
        searchEnabled = try container.decode(Bool.self, forKey: .searchEnabled)
        mutesEnabled = try container.decode(Bool.self, forKey: .mutesEnabled)
        urlEnrichmentEnabled = try container.decode(Bool.self, forKey: .urlEnrichmentEnabled)
        messageRetention = try container.decode(String.self, forKey: .messageRetention)
        maxMessageLength = try container.decode(Int.self, forKey: .maxMessageLength)
        let commands = try container.decodeIfPresent([Command].self, forKey: .commands) ?? []
        // We exclude the flag commands since it's not implemented by backend
        // and it'll be removed soon.
        // TODO: Remove this line of code when backend stops sending the `flag` command
        self.commands = commands.filter { $0.name != "flag" }

        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    internal required init(
        reactionsEnabled: Bool = false,
        typingEventsEnabled: Bool = false,
        readEventsEnabled: Bool = false,
        connectEventsEnabled: Bool = false,
        uploadsEnabled: Bool = false,
        repliesEnabled: Bool = false,
        quotesEnabled: Bool = false,
        searchEnabled: Bool = false,
        mutesEnabled: Bool = false,
        urlEnrichmentEnabled: Bool = false,
        messageRetention: String = "",
        maxMessageLength: Int = 0,
        commands: [Command] = [],
        createdAt: Date = .init(),
        updatedAt: Date = .init()
    ) {
        self.reactionsEnabled = reactionsEnabled
        self.typingEventsEnabled = typingEventsEnabled
        self.readEventsEnabled = readEventsEnabled
        self.connectEventsEnabled = connectEventsEnabled
        self.uploadsEnabled = uploadsEnabled
        self.repliesEnabled = repliesEnabled
        self.quotesEnabled = quotesEnabled
        self.searchEnabled = searchEnabled
        self.mutesEnabled = mutesEnabled
        self.urlEnrichmentEnabled = urlEnrichmentEnabled
        self.messageRetention = messageRetention
        self.maxMessageLength = maxMessageLength
        self.commands = commands
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
