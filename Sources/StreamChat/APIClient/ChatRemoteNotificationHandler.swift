//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation
import UserNotifications

public class MessageNotificationContent {
    public let message: ChatMessage
    public let channel: ChatChannel?
    public let reaction: PushReactionInfo?
    public let type: PushNotificationType

    init(
        message: ChatMessage,
        channel: ChatChannel?,
        reaction: PushReactionInfo?,
        type: PushNotificationType
    ) {
        self.message = message
        self.channel = channel
        self.reaction = reaction
        self.type = type
    }
}

/// The type of push notifications supported by the Stream Chat SDK.
public struct PushNotificationType: Equatable {
    public var name: String

    init(eventType: EventType) {
        name = eventType.rawValue
    }

    /// When the push notification is for a new message.
    public static var messageNew: PushNotificationType = .init(eventType: .messageNew)
    /// When the push notification is for a message reminder that is overdue.
    public static var messageReminderDue: PushNotificationType = .init(eventType: .messageReminderDue)
    /// When the push notification is for a message that has been updated.
    public static var messageUpdated: PushNotificationType = .init(eventType: .messageUpdated)
    /// When the push notification is for a new reaction.
    public static var reactionNew: PushNotificationType = .init(eventType: .reactionNew)
}

public class UnknownNotificationContent {
    public let content: UNNotificationContent

    public init(content: UNNotificationContent) {
        self.content = content
    }
}

public enum ChatPushNotificationContent {
    case message(MessageNotificationContent)
    case unknown(UnknownNotificationContent)
}

enum ChatPushNotificationError: Error {
    case invalidUserInfo(String)
}

public class ChatPushNotificationInfo {
    public let cid: ChannelId?
    public let messageId: MessageId?
    public let eventType: EventType?
    public let custom: [String: String]?

    public init(content: UNNotificationContent) throws {
        guard let payload = content.userInfo["stream"], let dict = payload as? [String: String] else {
            throw ChatPushNotificationError.invalidUserInfo("missing stream key or not a [string:string] dict")
        }

        guard let type = dict["type"] else {
            throw ChatPushNotificationError.invalidUserInfo("missing stream.type key")
        }

        eventType = EventType(rawValue: type)

        if let cid = dict["cid"] {
            self.cid = try? ChannelId(cid: cid)
        } else {
            cid = nil
        }

        if EventType.messageNew.rawValue == type, let id = dict["id"] {
            messageId = MessageId(id)
        } else {
            messageId = nil
        }

        custom = dict.removingValues(forKeys: ["cid", "type", "id"])
    }
}

/// The information about a reaction in a push notification.
public struct PushReactionInfo {
    /// The type of the reaction.
    public let type: MessageReactionType
    /// The id of the user who created the reaction.
    public let reactionUserId: UserId
    /// The image URL of the user who created the reaction.
    public let reactionUserImageUrl: URL?
    /// The id of the user who is the receiver of the reaction, usually the creator of the message.
    public let receiverUserId: UserId

    init?(payload: [String: String]) {
        guard let rawType = payload["reaction_type"],
              let reactionUserId = payload["reaction_user_id"],
              let receiverUserId = payload["receiver_id"] else {
            return nil
        }
        type = .init(rawValue: rawType)
        self.reactionUserId = UserId(reactionUserId)
        self.receiverUserId = UserId(receiverUserId)

        if let imageUrlString = payload["reaction_user_image"] {
            reactionUserImageUrl = URL(string: imageUrlString)
        } else {
            reactionUserImageUrl = nil
        }
    }
}

public class ChatRemoteNotificationHandler {
    var client: ChatClient
    var content: UNNotificationContent
    let chatCategoryIdentifiers: Set<String> = ["stream.chat", "MESSAGE_NEW"]
    let channelRepository: ChannelRepository
    let messageRepository: MessageRepository

    public init(client: ChatClient, content: UNNotificationContent) {
        self.client = client
        self.content = content
        channelRepository = client.channelRepository
        messageRepository = client.messageRepository
    }

    public func handleNotification(completion: @escaping (ChatPushNotificationContent) -> Void) -> Bool {
        guard chatCategoryIdentifiers.contains(content.categoryIdentifier) else {
            return false
        }

        getContent(completion: completion)
        return true
    }

    /// Marks the message as delivered and throttles the requests to at most one per second.
    public func markMessageAsDelivered(_ messageId: MessageId, for channel: ChatChannel) {
        /// Make sure if the message was already delivered, do not mark it as delivered.
        guard let message = channel.messageToMarkAsDelivered, message.messageId == messageId else {
            log.debug("No message to be marked as delivered for messageId:\(messageId))")
            return
        }

        let deliveredMessageInfo = DeliveredMessageInfo(
            channelId: channel.cid,
            messageId: messageId
        )
        client.currentUserController().markChannelsDelivered(
            deliveredMessages: [deliveredMessageInfo]
        ) { error in
            if let error = error {
                log.error("Failed to mark messages as delivered: \(error)")
            } else {
                log.debug("Successfully marked messageId:\(messageId) as delivered")
            }
        }
    }

    private func getContent(completion: @escaping (ChatPushNotificationContent) -> Void) {
        guard let payload = content.userInfo["stream"], let dict = payload as? [String: String] else {
            return completion(.unknown(UnknownNotificationContent(content: content)))
        }

        guard let cid = dict["cid"], let id = dict["id"] ?? dict["message_id"], let channelId = try? ChannelId(cid: cid) else {
            completion(.unknown(UnknownNotificationContent(content: content)))
            return
        }

        guard let type = dict["type"] else {
            return completion(.unknown(UnknownNotificationContent(content: content)))
        }
        
        getContent(cid: channelId, messageId: id) { message, channel in
            guard let message = message else {
                completion(.unknown(UnknownNotificationContent(content: self.content)))
                return
            }
            let pushType = PushNotificationType(eventType: EventType(rawValue: type))
            let content = MessageNotificationContent(
                message: message,
                channel: channel,
                reaction: PushReactionInfo(payload: dict),
                type: pushType
            )
            completion(.message(content))
        }
    }
    
    private func getContent(cid: ChannelId, messageId: MessageId, completion: @escaping (ChatMessage?, ChatChannel?) -> Void) {
        var query = ChannelQuery(cid: cid, pageSize: 10, membersLimit: 10)
        query.options = .state
        channelRepository.getChannel(for: query, store: false) { [messageRepository] channelResult in
            let channel = channelResult.value
            // When message is already available, skip fetching the message
            if let message = channel?.latestMessages.first(where: { $0.id == messageId }) {
                completion(message, channel)
            } else {
                messageRepository.getMessage(cid: cid, messageId: messageId, store: false) { messageResult in
                    completion(messageResult.value, channel)
                }
            }
        }
    }
}
