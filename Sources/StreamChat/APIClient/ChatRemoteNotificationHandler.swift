//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation
import UserNotifications

public class MessageNotificationContent {
    public let message: ChatMessage
    public let channel: ChatChannel?

    init(message: ChatMessage, channel: ChatChannel?) {
        self.message = message
        self.channel = channel
    }
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

public class ChatRemoteNotificationHandler {
    var client: ChatClient
    var content: UNNotificationContent
    let chatCategoryIdentifiers: Set<String> = ["stream.chat", "MESSAGE_NEW"]
    let database: DatabaseContainer
    let syncRepository: SyncRepository
    let messageRepository: MessageRepository
    let extensionLifecycle: NotificationExtensionLifecycle

    public init(client: ChatClient, content: UNNotificationContent) {
        self.client = client
        self.content = content
        database = client.databaseContainer
        syncRepository = client.syncRepository
        messageRepository = client.messageRepository
        extensionLifecycle = client.extensionLifecycle
    }

    public func handleNotification(completion: @escaping (ChatPushNotificationContent) -> Void) -> Bool {
        guard chatCategoryIdentifiers.contains(content.categoryIdentifier) else {
            return false
        }

        getContent(completion: completion)
        return true
    }

    private func getContent(completion: @escaping (ChatPushNotificationContent) -> Void) {
        guard let payload = content.userInfo["stream"], let dict = payload as? [String: String] else {
            return completion(.unknown(UnknownNotificationContent(content: content)))
        }

        guard let type = dict["type"] else {
            return completion(.unknown(UnknownNotificationContent(content: content)))
        }

        if EventType(rawValue: type) == .messageNew {
            guard let cid = dict["cid"], let id = dict["id"], let channelId = try? ChannelId(cid: cid) else {
                completion(.unknown(UnknownNotificationContent(content: content)))
                return
            }
            getMessageAndSync(cid: channelId, messageId: id) { (message, channel) in
                guard let message = message else {
                    completion(.unknown(UnknownNotificationContent(content: self.content)))
                    return
                }
                completion(.message(MessageNotificationContent(message: message, channel: channel)))
            }
        } else {
            completion(.unknown(UnknownNotificationContent(content: content)))
        }
    }

    private func getMessageAndSync(cid: ChannelId, messageId: String, completion: @escaping (ChatMessage?, ChatChannel?) -> Void) {
        let database = self.database
        messageRepository.getMessage(
            cid: cid,
            messageId: messageId,
            store: !extensionLifecycle.isAppReceivingWebSocketEvents
        ) { [weak self] result in
            guard case let .success(message) = result else {
                completion(nil, nil)
                return
            }

            self?.syncRepository.syncExistingChannelsEvents { _ in
                database.backgroundReadOnlyContext.perform {
                    let channel = try? ChannelDTO.load(cid: cid, context: database.backgroundReadOnlyContext)?.asModel()
                    completion(message, channel)
                }
            }
        }
    }
}
