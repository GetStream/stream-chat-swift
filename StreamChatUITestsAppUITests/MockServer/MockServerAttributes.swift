//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

enum MockFiles: String {
    case httpMessage = "http_message"
    case httpChatEvent = "http_events"
    case httpReaction = "http_reaction"
    case wsMessage = "ws_message"
    case wsChatEvent = "ws_events"
    case wsReaction = "ws_reaction"
    case wsHealthCheck = "HealthCheck"
    case httpChannel = "Channel"
    case httpChannelsQuery = "ChannelsQuery"
}

struct MockEndpoints {
    static var connect = "/connect"
    static var message = "/channels/messaging/:channel_id/message"
    static var messageUpdate = "/messages/:message_id"
    static var event = "/channels/messaging/:channel_id/event"
    static var messageRead = "/channels/messaging/:channel_id/read"
    static var reaction = "/messages/:message_id/reaction"
    static var reactionUpdate = "/messages/:message_id/reaction/:reaction_type"
    static var channels = "/channels"
    static var query = "/channels/messaging/:channel_id/query"
}

enum MessageTypes: String {
    case regular
    case deleted
}

enum MessageDetails: String {
    case messageId
    case text
    case createdAt
    case updatedAt
}

enum TopLevelKeys: String {
    case message
    case reaction
    case event
    case type
    case createdAt
}
