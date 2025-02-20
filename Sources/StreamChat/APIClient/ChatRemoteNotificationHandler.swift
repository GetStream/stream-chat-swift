//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
            getContent(cid: channelId, messageId: id) { message, channel in
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
