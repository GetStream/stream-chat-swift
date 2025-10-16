//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var request: UNNotificationRequest?
    var chatHandler: ChatRemoteNotificationHandler?

    func addAttachments(
        url: URL,
        content: UNMutableNotificationContent,
        identifier: String = "image",
        completion: @escaping (UNMutableNotificationContent) -> Void
    ) {
        let task = URLSession.shared.downloadTask(with: url) { (downloadedUrl, _, _) in
            defer {
                completion(content)
            }

            guard let downloadedUrl = downloadedUrl else {
                return
            }

            guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
                return
            }

            // UNNotificationAttachment requires path extension to be set (fallback to jpeg if not set)
            var localURL = URL(fileURLWithPath: path).appendingPathComponent(UUID().uuidString + url.lastPathComponent)
            if localURL.pathExtension.isEmpty {
                localURL.appendPathExtension("jpeg")
            }

            do {
                try FileManager.default.moveItem(at: downloadedUrl, to: localURL)
            } catch {
                return
            }

            guard let attachment = try? UNNotificationAttachment(identifier: identifier, url: localURL, options: nil) else {
                return
            }

            content.attachments = [attachment]
        }
        task.resume()
    }

    func addMessageAttachments(
        message: ChatMessage,
        content: UNMutableNotificationContent,
        completion: @escaping (UNMutableNotificationContent) -> Void
    ) {
        if let imageURL = message.author.imageURL {
            addAttachments(url: imageURL, content: content) {
                completion($0)
            }
            return
        }
        if let attachment = message.imageAttachments.first {
            addAttachments(url: attachment.imageURL, content: content) {
                completion($0)
            }
            return
        }
    }

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        self.request = request

        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
            return
        }

        guard let userCredentials = UserDefaults.shared.currentUser else {
            contentHandler(content)
            return
        }

        var config = ChatClientConfig(apiKey: .init(apiKeyString))
        config.applicationGroupIdentifier = applicationGroupIdentifier

        let client = ChatClient(config: config)
        client.setToken(token: Token(stringLiteral: userCredentials.token.rawValue))

        chatHandler = ChatRemoteNotificationHandler(client: client, content: content)

        let chatNotification = chatHandler?.handleNotification { chatContent in
            switch chatContent {
            case let .message(messageNotification):
                switch messageNotification.type {
                case .messageNew:
                    let authorName = messageNotification.message.author.name ?? "somebody"
                    let channelName = messageNotification.channel?.name ?? "a conversation with you"
                    content.title = "\(authorName) on \(channelName)"
                    content.subtitle = ""
                    content.body = messageNotification.message.text
                    
                    // Mark the message as delivered
                    if let channel = messageNotification.channel {
                        self.chatHandler?.markMessageAsDelivered(messageNotification.message.id, for: channel)
                    }
                    
                    self.addMessageAttachments(message: messageNotification.message, content: content) {
                        contentHandler($0)
                    }
                case .messageUpdated:
                    return contentHandler(content)
                case .messageReminderDue:
                    return contentHandler(content)
                case .reactionNew:
                    let emojis = self.reactionEmojis
                    var newBody = content.body
                    if let reactionInfo = messageNotification.reaction {
                        let reactionType = reactionInfo.type
                        newBody = newBody.replacingOccurrences(of: ":\(reactionType.rawValue):", with: emojis[reactionType] ?? "")
                    }
                    content.body = newBody
                    return contentHandler(content)
                default:
                    content.title = "You received an update to one conversation"
                    contentHandler(content)
                }
            default:
                content.title = "You received an update to one conversation"
                contentHandler(content)
            }
        }

        if chatNotification == false {
            // this was not a notification from Stream Chat
            // perform any other transformation to the notification if needed
            contentHandler(content)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler,
           let bestAttemptContent = request?.content.mutableCopy() as? UNMutableNotificationContent {
            contentHandler(bestAttemptContent)
        }
    }

    private var reactionEmojis: [MessageReactionType: String] = [
        "love": "❤️",
        "haha": "😂",
        "like": "👍",
        "sad": "👎",
        "wow": "😮"
    ]
}
