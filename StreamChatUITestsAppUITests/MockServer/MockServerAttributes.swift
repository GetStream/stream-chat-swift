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
}

enum MockEndpoint {
    static let connect = "/connect"
    
    static let messageUpdate = "/messages/\(EndpointQuery.messageId)"
    static let replies = "/messages/\(EndpointQuery.messageId)/replies"
    static let reaction = "/messages/\(EndpointQuery.messageId)/reaction"
    static let reactionUpdate = "/messages/\(EndpointQuery.messageId)/reaction/\(EndpointQuery.reactionType)"
    
    static let channels = "/channels"
    static let event = "/channels/messaging/\(EndpointQuery.channelId)/event"
    static let query = "/channels/messaging/\(EndpointQuery.channelId)/query"
    static let messageRead = "/channels/messaging/\(EndpointQuery.channelId)/read"
    static let message = "/channels/messaging/\(EndpointQuery.channelId)/message"
}

enum EndpointQuery {
    static let messageId = ":message_id"
    static let channelId = ":channel_id"
    static let reactionType = ":reaction_type"
}

enum MessageType: String {
    case regular
    case deleted
}

enum TopLevelKey {
    static let messages = "messages"
    static let message = "message"
    static let reaction = "reaction"
    static let event = "event"
    static let channels = "channels"
    static let user = "user"
    static let userId = "user_id"
    static let cid = "cid"
    static let channelId = "channel_id"
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
    
    static let countDooku = [
        UserPayloadsCodingKeys.id.rawValue: "count_dooku",
        UserPayloadsCodingKeys.name.rawValue: "Count Dooku",
        UserPayloadsCodingKeys.imageURL.rawValue: "https://vignette.wikia.nocookie.net/starwars/images/b/b8/Dooku_Headshot.jpg"
    ]
}
