//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat

enum MockFile: String {
    case httpMessage = "http_message"
    case httpChatEvent = "http_events"
    case httpReaction = "http_reaction"
    case httpReplies = "http_replies"
    case httpMember = "http_member"
    case wsMessage = "ws_message"
    case wsChatEvent = "ws_events"
    case wsChannelEvent = "ws_events_channel"
    case wsMemberEvent = "ws_events_member"
    case wsReaction = "ws_reaction"
    case wsHealthCheck = "ws_health_check"
    case httpChannels = "http_channels"
}

struct MockEndpoint {
    static let connect = "/connect"
    
    static let messageUpdate = "/messages/\(EndpointQuery.messageId)"
    static let replies = "/messages/\(EndpointQuery.messageId)/replies"
    static let reaction = "/messages/\(EndpointQuery.messageId)/reaction"
    static let reactionUpdate = "/messages/\(EndpointQuery.messageId)/reaction/\(EndpointQuery.reactionType)"
    
    static let channels = "/channels"
    static let channel = "/channels/messaging/\(EndpointQuery.channelId)"
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

struct JSONKey {
    static let messages = "messages"
    static let message = "message"
    static let reaction = "reaction"
    static let event = "event"
    static let channels = "channels"
    static let user = "user"
    static let userId = "user_id"
    static let cid = "cid"
    static let channel = "channel"
    static let channelId = "channel_id"
    static let channelType = "channel_type"
    static let createdAt = "created_at"
    static let eventType = "type"
    static let members = "members"
    static let member = "member"
    static let id = "id"

    struct Channel {
        static let addMembers = "add_members"
        static let removeMembers = "remove_members"
    }
}

struct UserDetails {

    static var users: [[String: Any]] {
        [
            hanSolo,
            lukeSkywalker,
            countDooku,
            leiaOrgana,
            landoCalrissian,
            chewbacca,
            r2d2
        ]
    }

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

    static let leiaOrganaId = "leia_organa"
    static let leiaOrgana = [
        UserPayloadsCodingKeys.id.rawValue: leiaOrganaId,
        UserPayloadsCodingKeys.name.rawValue: "Leia Organa",
        UserPayloadsCodingKeys.imageURL.rawValue: "https://vignette.wikia.nocookie.net/starwars/images/f/fc/Leia_Organa_TLJ.png"
    ]

    static let landoCalrissian = [
        UserPayloadsCodingKeys.id.rawValue: "lando_calrissian",
        UserPayloadsCodingKeys.name.rawValue: "Lando Calrissian",
        UserPayloadsCodingKeys.imageURL.rawValue: "https://vignette.wikia.nocookie.net/starwars/images/8/8f/Lando_ROTJ.png"
    ]

    static let chewbacca = [
        UserPayloadsCodingKeys.id.rawValue: "chewbacca",
        UserPayloadsCodingKeys.name.rawValue: "Chewbacca",
        UserPayloadsCodingKeys.imageURL.rawValue: "https://vignette.wikia.nocookie.net/starwars/images/4/48/Chewbacca_TLJ.png"
    ]

    static let r2d2 = [
        UserPayloadsCodingKeys.id.rawValue: "r2-d2",
        UserPayloadsCodingKeys.name.rawValue: "R2-D2",
        UserPayloadsCodingKeys.imageURL.rawValue: "https://vignette.wikia.nocookie.net/starwars/images/e/eb/ArtooTFA2-Fathead.png"
    ]

    static func unknownUser(withUserId userId: String) -> [String: Any] {
        [
            UserPayloadsCodingKeys.id.rawValue: userId,
            UserPayloadsCodingKeys.name.rawValue: userName(for: userId),
            UserPayloadsCodingKeys.imageURL.rawValue: "https://vignette.wikia.nocookie.net/starwars/images/f/fc/Leia_Organa_TLJ.png"
        ]
    }

    static func userName(for id: String) -> String {
        id
            .split(separator: "_")
            .map { $0.capitalizingFirstLetter() }
            .joined(separator: " ")
    }

    static func user(withUserId userId: String) -> (id: String, name: String, url: String) {
        var user = UserDetails.users.first(where: { ($0[UserPayloadsCodingKeys.id.rawValue] as? String) == userId })

        if user == nil {
            user = UserDetails.unknownUser(withUserId: userId)
        }

        return (
            (user?[UserPayloadsCodingKeys.id.rawValue] as? String) ?? leiaOrganaId,
            (user?[UserPayloadsCodingKeys.name.rawValue] as? String) ?? "Leia Organa",
            (user?[UserPayloadsCodingKeys.imageURL.rawValue] as? String) ?? "https://vignette.wikia.nocookie.net/starwars/images/f/fc/Leia_Organa_TLJ.png"
        )
    }
}
