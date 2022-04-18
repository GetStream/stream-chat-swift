//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat

enum MockFile: String {
    case httpMessage = "http_message"
    case httpChatEvent = "http_events"
    case httpReaction = "http_reaction"
    case httpReplies = "http_replies"
    case wsMessage = "ws_message"
    case wsChatEvent = "ws_events"
    case wsReaction = "ws_reaction"
    case wsHealthCheck = "ws_health_check"
    case httpChannels = "http_channels"
    case httpChannelQuery = "http_channel_query"
}

enum MockEndpoint {
    static let connect = "/connect"
    
    static let messageUpdate = "/messages/:message_id"
    static let replies = "/messages/:message_id/replies"
    static let reaction = "/messages/:message_id/reaction"
    static let reactionUpdate = "/messages/:message_id/reaction/:reaction_type"
    
    static let channels = "/channels"
    static let event = "/channels/messaging/:channel_id/event"
    static let query = "/channels/messaging/:channel_id/query"
    static let messageRead = "/channels/messaging/:channel_id/read"
    static let message = "/channels/messaging/:channel_id/message"
}

enum MessageType: String {
    case regular
    case deleted
}

struct TopLevelKey {
    static let messages = "messages"
    static let message = "message"
    static let reaction = "reaction"
    static let event = "event"
    static let channels = "channels"
    static let user = "user"
}

enum UserDetails {
    static let hanSolo = [
        UserPayloadsCodingKeys.id.rawValue: "han_solo",
        UserPayloadsCodingKeys.name.rawValue: "Han Solo",
        UserPayloadsCodingKeys.imageURL.rawValue: "https://vignette.wikia.nocookie.net/starwars/images/e/e2/TFAHanSolo.png"
    ]

    static let lukeSkywalker = [
        UserPayloadsCodingKeys.id.rawValue: "luke_skywalker",
        UserPayloadsCodingKeys.name.rawValue: "Luke Skywalker",
        UserPayloadsCodingKeys.imageURL.rawValue: "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg"
    ]
}
