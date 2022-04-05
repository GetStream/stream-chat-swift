//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var request: UNNotificationRequest?

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
          
            let localURL = URL(fileURLWithPath: path).appendingPathComponent(url.lastPathComponent)
          
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

        guard let userId = UserDefaults(suiteName: applicationGroupIdentifier)?.string(forKey: currentUserIdRegisteredForPush),
              let userCredentials = UserCredentials.builtInUsersByID(id: userId) else {
            contentHandler(content)
            return
        }

        var config = ChatClientConfig(apiKey: .init(apiKeyString))
//        config.isLocalStorageEnabled = true
        config.applicationGroupIdentifier = applicationGroupIdentifier

        let client = ChatClient(config: config)
        client.setToken(token: Token(stringLiteral: userCredentials.token))

        let chatHandler = ChatRemoteNotificationHandler(client: client, content: content)

        let chatNotification = chatHandler.handleNotification { chatContent in
            switch chatContent {
            case let .message(messageNotification):
                content
                    .title = (messageNotification.message.author.name ?? "somebody") +
                    (" on \(messageNotification.channel?.name ?? "a conversation with you")")
                content.subtitle = ""
                content.body = messageNotification.message.text
                self.addMessageAttachments(message: messageNotification.message, content: content) {
                    contentHandler($0)
                }
            default:
                content.title = "You received an update to one conversation"
                contentHandler(content)
            }
        }
        
        if !chatNotification {
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
}
