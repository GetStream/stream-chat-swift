//
//  NotificationService.swift
//  DemoAppPush
//
//  Created by tommaso barbugli on 25/08/2021.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UserNotifications
import StreamChat

public enum ChatPushNotificationContent {
    case message(ChatMessage)
    case reaction(ChatMessageReaction)
    case unknown(UNMutableNotificationContent)
}

/// 1 - get the payload and decide what kind of payload it is
/// 2 - get the ChatClient
/// 3 - if the payload is v2 then we need to fetch the full message
/// 4 - if offline storage is enabled, we need to call sync
class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    func getContent(from content: UNMutableNotificationContent, completion: @escaping (ChatPushNotificationContent) -> Void) {
        let client = getClient()

        guard let payload = content.userInfo["stream"], let dict = payload as? [String: String] else {
            return completion(.unknown(content))
        }

        guard let type = dict["type"] else {
            return completion(.unknown(content))
        }

        switch EventType.init(rawValue: type) {
            case .messageNew:
                guard let cid = dict["cid"], let id = dict["id"], let cid = try? ChannelId.init(cid: cid) else {
                    completion(.unknown(content))
                    return
                }
                let controller  = client.messageController(cid: cid, messageId: id)
                controller.synchronize { error in
                    if let error = error {
                        log.error(error)
                        completion(.unknown(content))
                    }
                    guard let message = controller.message else {
                        completion(.unknown(content))
                        return
                    }
                    completion(.message(message))
                }
            case .reactionNew:
                completion(.unknown(content))
            default:
                completion(.unknown(content))
        }
    }

    func getClient() -> ChatClient {
        let config = ChatClientConfig(apiKey: .init("api_key"))
        let client = ChatClient(config: config) { completion in completion(.success("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZ2VuZXJhbF9ncmlldm91cyJ9.FPRvRoeZdALErBA1bDybch4xY-c5CEinuc9qqEPzX4E")) }
        return client
    }

    func rewrite(content: ChatPushNotificationContent, notification: UNMutableNotificationContent) {
        notification.title = "\(content)"
//        switch content {
//        case .unknown:
//            bestAttemptContent.title = "unknown"
//
//        }
    }

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let bestAttemptContent = bestAttemptContent {
            getContent(from: bestAttemptContent) { content in
                self.rewrite(content: content, notification: bestAttemptContent)
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
