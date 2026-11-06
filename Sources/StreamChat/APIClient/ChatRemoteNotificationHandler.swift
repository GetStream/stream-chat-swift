//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
public struct PushNotificationType: Equatable, Sendable {
    public var name: String

    init(eventType: EventType) {
        name = eventType.rawValue
    }

    /// When the push notification is for a new message.
    public static let messageNew: PushNotificationType = .init(eventType: .messageNew)
    /// When the push notification is for a message reminder that is overdue.
    public static let messageReminderDue: PushNotificationType = .init(eventType: .messageReminderDue)
    /// When the push notification is for a message that has been updated.
    public static let messageUpdated: PushNotificationType = .init(eventType: .messageUpdated)
    /// When the push notification is for a new reaction.
    public static let reactionNew: PushNotificationType = .init(eventType: .reactionNew)
}

@available(tvOS, unavailable)
public class UnknownNotificationContent {
    public let content: UNNotificationContent

    public init(content: UNNotificationContent) {
        self.content = content
    }
}

@available(tvOS, unavailable)
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

    @available(tvOS, unavailable)
    public convenience init(content: UNNotificationContent) throws {
        try self.init(userInfo: content.userInfo)
    }

    /// Creates the push notification info from the payload of a remote notification.
    ///
    /// - Parameter userInfo: The payload, such as the `userInfo` of `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)`.
    public init(userInfo: [AnyHashable: Any]) throws {
        guard let payload = userInfo["stream"], let dict = payload as? [String: String] else {
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
    let content: UNNotificationContent?
    let categoryIdentifier: String
    let payload: [String: String]?
    let chatCategoryIdentifiers: Set<String> = ["stream.chat", "MESSAGE_NEW"]
    let channelRepository: ChannelRepository
    let messageRepository: MessageRepository
    let currentUserUpdater: CurrentUserUpdater
    let deliveryCriteriaValidator: MessageDeliveryCriteriaValidating

    @available(tvOS, unavailable)
    public convenience init(
        client: ChatClient,
        content: UNNotificationContent
    ) {
        self.init(
            client: client,
            content: content,
            categoryIdentifier: content.categoryIdentifier,
            userInfo: content.userInfo
        )
    }

    /// Creates a handler for the payload of a remote notification.
    ///
    /// Use ``handlePayload(completion:)`` to fetch the message the notification is about.
    /// - Parameters:
    ///   - client: The client used for fetching the message and its channel.
    ///   - userInfo: The payload, such as the `userInfo` of `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)`.
    public convenience init(
        client: ChatClient,
        userInfo: [AnyHashable: Any]
    ) {
        let categoryIdentifier = (userInfo["aps"] as? [String: Any])?["category"] as? String ?? ""
        #if os(tvOS)
        let content: UNNotificationContent? = nil
        #else
        let mutableContent = UNMutableNotificationContent()
        mutableContent.userInfo = userInfo
        mutableContent.categoryIdentifier = categoryIdentifier
        let content: UNNotificationContent? = mutableContent
        #endif
        self.init(client: client, content: content, categoryIdentifier: categoryIdentifier, userInfo: userInfo)
    }

    private init(
        client: ChatClient,
        content: UNNotificationContent?,
        categoryIdentifier: String,
        userInfo: [AnyHashable: Any]
    ) {
        self.client = client
        self.content = content
        self.categoryIdentifier = categoryIdentifier
        payload = userInfo["stream"] as? [String: String]
        channelRepository = client.channelRepository
        messageRepository = client.messageRepository
        currentUserUpdater = CurrentUserUpdater(
            database: client.databaseContainer,
            apiClient: client.apiClient
        )
        self.deliveryCriteriaValidator = MessageDeliveryCriteriaValidator()
    }

    @available(tvOS, unavailable)
    public func handleNotification(completion: @escaping @Sendable (ChatPushNotificationContent) -> Void) -> Bool {
        guard let content, chatCategoryIdentifiers.contains(categoryIdentifier) else {
            return false
        }

        nonisolated(unsafe) let unknownContent = UnknownNotificationContent(content: content)
        getContent { result in
            switch result {
            case let .success(messageContent):
                completion(.message(messageContent))
            case .failure:
                completion(.unknown(unknownContent))
            }
        }
        return true
    }

    /// Fetches the message and channel of a Stream Chat notification.
    ///
    /// A notification is from Stream Chat when its `aps.category` is a Stream Chat category, or when its `stream`
    /// payload has `"sender": "stream.chat"`.
    /// - Parameter completion: Called with the message content, or an error when the payload is invalid or the
    ///   message can't be fetched. It isn't called when the notification isn't from Stream Chat.
    /// - Returns: `true` when the notification is from Stream Chat, otherwise `false`.
    public func handlePayload(completion: @escaping @Sendable (Result<MessageNotificationContent, Error>) -> Void) -> Bool {
        guard chatCategoryIdentifiers.contains(categoryIdentifier) || payload?["sender"] == "stream.chat" else {
            return false
        }

        getContent(completion: completion)
        return true
    }

    /// Marks the message as delivered from a push notification if the app is not active.
    public func markMessageAsDelivered(_ message: ChatMessage, for channel: ChatChannel) {
        guard let currentUser = client.currentUserController().currentUser else {
            return log.debug("No current user to mark messages as delivered")
        }
        // Make sure if the message was already delivered, do not mark it as delivered.
        // If the app is active, the middleware will mark it as delivered so the push
        // does not need to do it.
        guard deliveryCriteriaValidator.canMarkMessageAsDelivered(message, for: currentUser, in: channel) else {
            log.debug("No message to be marked as delivered for messageId:\(message.id))")
            return
        }

        let deliveryInfo = MessageDeliveryInfo(channelId: channel.cid, messageId: message.id)
        currentUserUpdater.markMessagesAsDelivered([deliveryInfo])
    }

    private func getContent(completion: @escaping @Sendable (Result<MessageNotificationContent, Error>) -> Void) {
        guard let dict = payload else {
            return completion(.failure(ChatPushNotificationError.invalidUserInfo("missing stream key or not a [string:string] dict")))
        }

        guard let cid = dict["cid"], let id = dict["id"] ?? dict["message_id"], let channelId = try? ChannelId(cid: cid) else {
            return completion(.failure(ChatPushNotificationError.invalidUserInfo("missing or invalid stream.cid or message id")))
        }

        guard let type = dict["type"] else {
            return completion(.failure(ChatPushNotificationError.invalidUserInfo("missing stream.type key")))
        }

        getContent(cid: channelId, messageId: id) { messageResult, channel in
            completion(messageResult.map { message in
                MessageNotificationContent(
                    message: message,
                    channel: channel,
                    reaction: PushReactionInfo(payload: dict),
                    type: PushNotificationType(eventType: EventType(rawValue: type))
                )
            })
        }
    }
    
    private func getContent(cid: ChannelId, messageId: MessageId, completion: @escaping @Sendable (Result<ChatMessage, Error>, ChatChannel?) -> Void) {
        var query = ChannelQuery(cid: cid, pageSize: 10, membersLimit: 10)
        query.options = .state
        channelRepository.getChannel(for: query, store: false) { [messageRepository] channelResult in
            let channel = channelResult.value
            // When message is already available, skip fetching the message
            if let message = channel?.latestMessages.first(where: { $0.id == messageId }) {
                completion(.success(message), channel)
            } else {
                messageRepository.getMessage(cid: cid, messageId: messageId, store: false) { messageResult in
                    completion(messageResult, channel)
                }
            }
        }
    }
}
