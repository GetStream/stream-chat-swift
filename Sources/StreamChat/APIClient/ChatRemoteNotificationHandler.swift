//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation
import UserNotifications

public struct MessageNotificationContent {
    public let message: ChatMessage
    public let channel: ChatChannel?
}

public struct ReactionNotificationContent {
    public let message: ChatMessage
    public let channel: ChatChannel?
}

public struct UnknownNotificationContent {
    public let content: UNNotificationContent
}

public enum ChatPushNotificationContent {
    case message(MessageNotificationContent)
    case reaction(ReactionNotificationContent)
    case unknown(UnknownNotificationContent)
}

enum ChatPushNotificationError: Error {
    case invalidUserInfo(String)
}

public struct ChatPushNotificationInfo {
    public let cid: ChannelId?
    public let messageId: MessageId?
    public let eventType: EventType?
    
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
    }
}

public class ChatRemoteNotificationHandler {
    var client: ChatClient
    var content: UNNotificationContent
    let chatCategoryIdentifiers: Set<String> = ["stream.chat", "MESSAGE_NEW"]
    /// do not call the sync endpoint more than once every six seconds
    let syncCooldown: TimeInterval = 6.0
    let database: DatabaseContainer

    public init(client: ChatClient, content: UNNotificationContent) {
        self.client = client
        self.content = content
        database = client.databaseContainer
    }

    public func handleNotification(completion: @escaping (ChatPushNotificationContent) -> Void) -> Bool {
        guard chatCategoryIdentifiers.contains(content.categoryIdentifier) else {
            return false
        }
        
        getContent(completion: completion)
        return true
    }

    private func obtainLastSyncDate(completion: @escaping (Date?) -> Void) {
        let context = database.viewContext
        context.perform {
            completion(context.currentUser?.lastSyncedAt)
        }
    }

    private func bumpLastSyncDate(_ lastSyncedAt: Date, completion: @escaping () -> Void) {
        database.write { session in
            session.currentUser?.lastSyncedAt = lastSyncedAt
        } completion: { error in
            if let error = error {
                log.error(error)
            }
            completion()
        }
    }

    private func shouldSyncWithAPI(since: Date, now: Date = .init()) -> Bool {
        now.timeIntervalSince(since) > syncCooldown
    }

    private func syncChannels(completion: @escaping () -> Void) {
        guard client.config.isLocalStorageEnabled else {
            completion()
            return
        }

        obtainLastSyncDate { lastSyncAt in
            guard let lastSyncAt = lastSyncAt, self.shouldSyncWithAPI(since: lastSyncAt) else {
                completion()
                return
            }

            let request = ChannelDTO.allChannelsFetchRequest
            request.fetchLimit = 1000
            request.propertiesToFetch = ["cid"]

            guard let results = try? self.database.viewContext.fetch(request) else {
                completion()
                return
            }

            let cids = results.compactMap { try? ChannelId(cid: $0.cid) }
            guard !cids.isEmpty else {
                completion()
                return
            }

            let endpoint: Endpoint<MissingEventsPayload> = .missingEvents(
                since: lastSyncAt,
                cids: cids
            )

            self.client.apiClient.request(endpoint: endpoint) {
                switch $0 {
                case let .success(payload):
                    self.client.eventNotificationCenter.addToCurrentBatchAndProcessImmediately(
                        payload.eventPayloads.compactMap { try? $0.event() }
                    ) {
                        let mostRecentEventDate = payload.eventPayloads.compactMap(\.createdAt).sorted().last
                        self.bumpLastSyncDate(
                            mostRecentEventDate ?? lastSyncAt,
                            completion: completion
                        )
                    }
                case let .failure(error):
                    log.error("Failed cleaning up channels data: \(error).")
                    completion()
                }
            }
        }
    }

    private func getMessageAndSync(cid: ChannelId, messageId: String, completion: @escaping (ChatMessage?, ChatChannel?) -> Void) {
        let controller = client.messageController(cid: cid, messageId: messageId)
        controller.synchronize { error in
            if let error = error {
                log.error(error)
                completion(nil, nil)
            }
            guard let message = controller.message else {
                completion(nil, nil)
                return
            }
            self.syncChannels() {
                let channel = ChannelDTO.load(cid: cid, context: self.database.viewContext)?.asModel()
                completion(message, channel)
            }
        }
    }

    private func getContent(completion: @escaping (ChatPushNotificationContent) -> Void) {
        guard let payload = content.userInfo["stream"], let dict = payload as? [String: String] else {
            return completion(.unknown(UnknownNotificationContent(content: content)))
        }

        guard let type = dict["type"] else {
            return completion(.unknown(UnknownNotificationContent(content: content)))
        }

        switch EventType(rawValue: type) {
        case .messageNew:
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
        default:
            completion(.unknown(UnknownNotificationContent(content: content)))
        }
    }
}
