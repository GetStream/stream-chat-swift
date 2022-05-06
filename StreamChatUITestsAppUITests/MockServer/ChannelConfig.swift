//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

@testable import StreamChat
import Swifter
import XCTest

// MARK: - Config

struct ChannelConfigs {

    private var configs: [String: ChannelConfig_Mock] = [:]

    func updateChannel(channel: inout [String: Any], withId id: String) {
        guard
            let config = configs[id],
            var configJson = channel[JSONKey.config] as? [String: Any]
        else {
            return
        }
        config.update(json: &configJson)
        channel[JSONKey.config] = configJson
    }

    mutating func updateConfig(config: ChannelConfig_Mock,
                               forChannelWithId id: String,
                               server: StreamMockServer) {
        var json = server.channelList
        guard
            var channels = json[JSONKey.channels] as? [[String: Any]],
            let channelIndex = server.channelIndex(withId: id),
            var channel = server.channel(withId: id),
            var innerChannel = channel[JSONKey.channel] as? [String: Any]
        else {
            return
        }

        configs[id] = config

        updateChannel(channel: &innerChannel, withId: id)

        channel[JSONKey.channel] = innerChannel
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

struct ChannelConfig_Mock: Codable {
    var typingEvents: Bool
    var readEvents: Bool
    var connectEvents: Bool
    var search: Bool
    var reactions: Bool
    var replies: Bool
    var quotes: Bool
    var mutes: Bool
    var uploads: Bool
    var urlEnrichment: Bool
    var customEvents: Bool
    var pushNotifications: Bool
    var reminders: Bool

    enum CodingKeys: String, CodingKey, CaseIterable {
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

    func update(json: inout [String: Any]) {
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

    init(data: Data) throws {
        self = try JSONDecoder().decode(ChannelConfig_Mock.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
}
