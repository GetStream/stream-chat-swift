//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@testable import StreamChat
import XCTest

// MARK: - Config

public struct ChannelConfigs {

    struct Cooldown {
        var isEnabled = false
        var duration: Int = 3
    }

    private var configs: [String: ChannelConfig_Mock] = [:]

    var coolDown = Cooldown()

    mutating func setCooldown(enabled value: Bool, duration: Int) {
        coolDown = Cooldown(isEnabled: value, duration: duration)
    }

    func updateChannel(channel: inout [String: Any], withId id: String) {
        guard
            let config = configs[id],
            var innerChannel = channel[JSONKey.channel] as? [String: Any],
            var configJson = innerChannel[JSONKey.config] as? [String: Any]
        else {
            return
        }
        config.update(json: &configJson)
        innerChannel[JSONKey.config] = configJson
        channel[JSONKey.channel] = innerChannel
    }

    mutating func updateConfig(config: ChannelConfig_Mock,
                               forChannelWithId id: String,
                               server: StreamMockServer) {
        var json = server.channelList
        guard
            var channels = json[JSONKey.channels] as? [[String: Any]],
            let channelIndex = server.channelIndex(withId: id),
            var channel = server.channel(withId: id)
        else {
            return
        }

        configs[id] = config

        updateChannel(channel: &channel, withId: id)
        channels[channelIndex] = channel
        json[JSONKey.channels] = channels
        server.channelList = json
    }

    mutating func config(forChannelId id: String,
                         server: StreamMockServer) -> ChannelConfig_Mock? {
        if let config = configs[id] { return config }

        let config = loadConfig(forChannelId: id, server: server)
        configs[id] = config
        return config
    }

    private func loadConfig(forChannelId id: String,
                            server: StreamMockServer) -> ChannelConfig_Mock? {
        guard
            let channel = server.channel(withId: id),
            let innerChannel = channel[JSONKey.channel] as? [String: Any],
            let configJson = (innerChannel[JSONKey.config] as? [String: Any])?.jsonToString()
        else {
            return nil
        }

        return try? ChannelConfig_Mock(configJson)
    }

}

public struct ChannelConfig_Mock: Codable {
    public var typingEvents: Bool
    public var readEvents: Bool
    public var connectEvents: Bool
    public var search: Bool
    public var reactions: Bool
    public var replies: Bool
    public var quotes: Bool
    public var mutes: Bool
    public var uploads: Bool
    public var urlEnrichment: Bool
    public var customEvents: Bool
    public var pushNotifications: Bool
    public var reminders: Bool

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case typingEvents = "typing_events"
        case readEvents = "read_events"
        case connectEvents = "connect_events"
        case search = "search"
        case reactions = "reactions"
        case replies = "replies"
        case quotes = "quotes"
        case mutes = "mutes"
        case uploads = "uploads"
        case urlEnrichment = "url_enrichment"
        case customEvents = "custom_events"
        case pushNotifications = "push_notifications"
        case reminders = "reminders"
    }

    public func update(json: inout [String: Any]) {
        json[CodingKeys.typingEvents.rawValue] = typingEvents
        json[CodingKeys.readEvents.rawValue] = readEvents
        json[CodingKeys.connectEvents.rawValue] = connectEvents
        json[CodingKeys.search.rawValue] = search
        json[CodingKeys.reactions.rawValue] = reactions
        json[CodingKeys.replies.rawValue] = replies
        json[CodingKeys.quotes.rawValue] = quotes
        json[CodingKeys.mutes.rawValue] = mutes
        json[CodingKeys.uploads.rawValue] = uploads
        json[CodingKeys.urlEnrichment.rawValue] = urlEnrichment
        json[CodingKeys.customEvents.rawValue] = customEvents
        json[CodingKeys.pushNotifications.rawValue] = pushNotifications
        json[CodingKeys.reminders.rawValue] = reminders
    }

    public init(data: Data) throws {
        self = try JSONDecoder().decode(ChannelConfig_Mock.self, from: data)
    }

    public init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
}
