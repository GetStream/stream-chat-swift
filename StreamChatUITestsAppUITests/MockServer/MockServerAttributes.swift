//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

enum MockFile: String {
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

enum MockEndpoint {
    static let connect = "/connect"
    static let message = "/channels/messaging/:channel_id/message"
    static let messageUpdate = "/messages/:message_id"
    static let event = "/channels/messaging/:channel_id/event"
    static let messageRead = "/channels/messaging/:channel_id/read"
    static let reaction = "/messages/:message_id/reaction"
    static let reactionUpdate = "/messages/:message_id/reaction/:reaction_type"
    static let channels = "/channels"
    static let query = "/channels/messaging/:channel_id/query"
}

enum MessageType: String {
    case regular
    case deleted
}

enum MessageDetail: String {
    case messageId
    case text
    case createdAt
    case updatedAt
}

enum TopLevelKey: String {
    case message
    case reaction
    case event
    case type
    case createdAt
}
