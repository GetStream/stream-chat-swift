//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Foundation

public enum Message {
    public static func message(withInvalidCommand command: String) -> String {
        "Sorry, command \(command) doesn't exist. Try posting your message without the starting /"
    }
    
    public static var blockedByModerationPolicies: String {
        "Message was blocked by moderation policies"
    }
}

public enum MockFile: String {
    case message = "http_message"
    case ephemeralMessage = "http_message_ephemeral"
    case httpChatEvent = "http_events"
    case httpReaction = "http_reaction"
    case httpReplies = "http_replies"
    case httpMember = "http_member"
    case httpChannels = "http_channels"
    case httpAttachment = "http_attachment"
    
    case wsChatEvent = "ws_events"
    case wsChannelEvent = "ws_events_channel"
    case wsMemberEvent = "ws_events_member"
    case wsUserEvent = "ws_events_user"
    case wsReaction = "ws_reaction"
    case wsHealthCheck = "ws_health_check"

    var filePath: String {
        "\(Bundle.testTools.pathToJSONsFolder)\(rawValue)"
    }
}

public enum MockEndpoint {
    public static let connect = "/connect"
    public static let messageUpdate = "/messages/\(EndpointQuery.messageId)"
    public static let replies = "/messages/\(EndpointQuery.messageId)/replies"
    public static let reaction = "/messages/\(EndpointQuery.messageId)/reaction"
    public static let reactionUpdate = "/messages/\(EndpointQuery.messageId)/reaction/\(EndpointQuery.reactionType)"
    public static let action = "/messages/\(EndpointQuery.messageId)/action"
    public static let channels = "/channels"
    public static let channel = "/channels/messaging/\(EndpointQuery.channelId)"
    public static let event = "/channels/messaging/\(EndpointQuery.channelId)/event"
    public static let query = "/channels/messaging/\(EndpointQuery.channelId)/query"
    public static let messageRead = "/channels/messaging/\(EndpointQuery.channelId)/read"
    public static let message = "/channels/messaging/\(EndpointQuery.channelId)/message"
    public static let image = "/channels/messaging/\(EndpointQuery.channelId)/image"
    public static let file = "/channels/messaging/\(EndpointQuery.channelId)/file"
}

public enum EndpointQuery {
    public static let messageId = ":message_id"
    public static let channelId = ":channel_id"
    public static let reactionType = ":reaction_type"
}

public enum JSONKey {
    public static let messages = "messages"
    public static let message = "message"
    public static let reaction = "reaction"
    public static let event = "event"
    public static let channels = "channels"
    public static let user = "user"
    public static let userId = "user_id"
    public static let cid = "cid"
    public static let channel = "channel"
    public static let channelId = "channel_id"
    public static let channelType = "channel_type"
    public static let config = "config"
    public static let createdAt = "created_at"
    public static let eventType = "type"
    public static let members = "members"
    public static let member = "member"
    public static let id = "id"
    public static let cooldown = "cooldown"
    public static let attachmentAction = "image_action"
    public static let file = "file"

    public enum Channel {
        public static let addMembers = "add_members"
        public static let removeMembers = "remove_members"
    }
    
    public enum AttachmentAction {
        public static let send = "send"
        public static let shuffle = "shuffle"
    }
}

public enum UserDetails {

    public static var users: [[String: String]] {
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

    public static let hanSolo = [
        UserPayloadsCodingKeys.id.rawValue: "han_solo",
        UserPayloadsCodingKeys.name.rawValue: "Han Solo",
        UserPayloadsCodingKeys.imageURL.rawValue: "https://vignette.wikia.nocookie.net/starwars/images/e/e2/TFAHanSolo.png"
    ]

    public static let currentUserId = "luke_skywalker"
    public static let lukeSkywalker = [
        UserPayloadsCodingKeys.id.rawValue: "luke_skywalker",
        UserPayloadsCodingKeys.name.rawValue: "Luke Skywalker",
        UserPayloadsCodingKeys.imageURL.rawValue: "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg"
    ]
    
    public static let countDooku = [
        UserPayloadsCodingKeys.id.rawValue: "count_dooku",
        UserPayloadsCodingKeys.name.rawValue: "Count Dooku",
        UserPayloadsCodingKeys.imageURL.rawValue: "https://vignette.wikia.nocookie.net/starwars/images/b/b8/Dooku_Headshot.jpg"
    ]

    public static let leiaOrganaId = "leia_organa"
    public static let leiaOrgana = [
        UserPayloadsCodingKeys.id.rawValue: leiaOrganaId,
        UserPayloadsCodingKeys.name.rawValue: "Leia Organa",
        UserPayloadsCodingKeys.imageURL.rawValue: "https://vignette.wikia.nocookie.net/starwars/images/f/fc/Leia_Organa_TLJ.png"
    ]

    public static let landoCalrissian = [
        UserPayloadsCodingKeys.id.rawValue: "lando_calrissian",
        UserPayloadsCodingKeys.name.rawValue: "Lando Calrissian",
        UserPayloadsCodingKeys.imageURL.rawValue: "https://vignette.wikia.nocookie.net/starwars/images/8/8f/Lando_ROTJ.png"
    ]

    public static let chewbacca = [
        UserPayloadsCodingKeys.id.rawValue: "chewbacca",
        UserPayloadsCodingKeys.name.rawValue: "Chewbacca",
        UserPayloadsCodingKeys.imageURL.rawValue: "https://vignette.wikia.nocookie.net/starwars/images/4/48/Chewbacca_TLJ.png"
    ]

    public static let r2d2 = [
        UserPayloadsCodingKeys.id.rawValue: "r2-d2",
        UserPayloadsCodingKeys.name.rawValue: "R2-D2",
        UserPayloadsCodingKeys.imageURL.rawValue: "https://vignette.wikia.nocookie.net/starwars/images/e/eb/ArtooTFA2-Fathead.png"
    ]

    public static func unknownUser(withUserId userId: String) -> [String: String] {
        [
            UserPayloadsCodingKeys.id.rawValue: userId,
            UserPayloadsCodingKeys.name.rawValue: userName(for: userId),
            UserPayloadsCodingKeys.imageURL.rawValue: "https://vignette.wikia.nocookie.net/starwars/images/f/fc/Leia_Organa_TLJ.png"
        ]
    }

    public static func userId(for user: [String: String]) -> String {
        user[UserPayloadsCodingKeys.id.rawValue] ?? leiaOrganaId
    }

    public static func userName(for id: String) -> String {
        id
            .split(separator: "_")
            .map { $0.capitalizingFirstLetter() }
            .joined(separator: " ")
    }

    public static func userTuple(withUserId userId: String) -> (id: String, name: String, url: String) {
        let user = user(withUserId: userId)
        return (
            user[UserPayloadsCodingKeys.id.rawValue] ?? leiaOrganaId,
            user[UserPayloadsCodingKeys.name.rawValue] ?? "Leia Organa",
            user[UserPayloadsCodingKeys.imageURL.rawValue] ?? "https://vignette.wikia.nocookie.net/starwars/images/f/fc/Leia_Organa_TLJ.png"
        )
    }

    public static func user(withUserId userId: String) -> [String: String] {
        guard let user = UserDetails.users.first(where: { $0[UserPayloadsCodingKeys.id.rawValue] == userId }) else {
            return UserDetails.unknownUser(withUserId: userId)
        }
        return user
    }
}

public enum Attachments {
    public static let image = "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg"
    public static let video = "https://download.samplelib.com/mp4/sample-5s.mp4"
    public static let file = "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"
}
