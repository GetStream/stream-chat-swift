//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/message-delivery-and-read-status/

import StreamChat
import UserNotifications

private extension ChatClient {
    static let shared = ChatClient(config: ChatClientConfig(apiKey: APIKey("<api_key>")))
}

struct Snippets_04_10_MessageReceipts {
    var client: ChatClient!
    var content: UNNotificationContent!

    func userPrivacySettings() {
        let currentUserController = ChatClient.shared.currentUserController()
        currentUserController.updateUserData(
          privacySettings: .init(
            deliveryReceipts: DeliveryReceiptsPrivacySettings(enabled: false)
          )
        )
    }

    func userPrivacySettings2() {
        let currentUserController = ChatClient.shared.currentUserController()
        currentUserController.updateUserData(
          privacySettings: .init(
            readReceipts: ReadReceiptsPrivacySettings(enabled: false)
          )
        )
    }

    func pushNotificationDeliveryConfirmation() {
        // In your NotificationService extension
        let chatHandler = ChatRemoteNotificationHandler(client: client, content: content)
        let chatNotification = chatHandler.handleNotification { chatContent in
          switch chatContent {
          case let .message(messageNotification):
            switch messageNotification.type {
            case .messageNew:
              if let channel = messageNotification.channel {
                chatHandler.markMessageAsDelivered(messageNotification.message, for: channel)
              }
            default:
              break
            }
          case .unknown:
            break
          }
        }
        suppressUnusedWarning(chatNotification)
    }
}
