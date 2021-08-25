//
//  NotificationViewController.swift
//  ChatPush
//
//  Created by tommaso barbugli on 25/08/2021.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import StreamChat

public enum ChatPushNotificationContent {
    case message(ChatMessage)
    case reaction(ChatMessageReaction)
    case unknown(UNNotificationContent)
}

/// 1 - get the payload and decide what kind of payload it is
/// 2 - get the ChatClient
/// 3 - if the payload is v2 then we need to fetch the full message
/// 4 - if offline storage is enabled, we need to call sync
class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var label: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }

    
    func decode(body: String) throws -> [String: RawJSON] {
        /// TODO: use JSONDecoder.stream instead of this (need to move this to internal code)
        return try JSONDecoder().decode([String: RawJSON].self, from: Data(body.utf8))
    }

    func getContent(from request: UNNotificationRequest, client: ChatClient) -> ChatPushNotificationContent {
        guard let content = try? decode(body: request.content.body) else {
            return .unknown(request.content)
        }

        guard case let .string(type) = content["type"] else {
            return .unknown(request.content)
        }
        
        switch EventType.init(rawValue: type) {
            case .messageNew:
                return .unknown(request.content)
            case .reactionNew:
                return .unknown(request.content)
            default:
                return .unknown(request.content)
        }
        
    }

    /// must implement this correctly!
    func getClient() -> ChatClient {
        let config = ChatClientConfig(apiKey: .init("api_key"))
        var client = ChatClient(config: config)
//        client.tokenProvider

        let controller  = client.messageController(cid: ChannelId.init(type: .custom(""), id: ""), messageId: "")
        controller.synchronize { error in
            if let error = error {
                print(error)
                return
            }
            if let message = controller.message {
                print("debugging: got a message! \(message)")
            }
            
        }
        return client
    }

    func didReceive(_ notification: UNNotification) {
        print("debugging: \(notification.request.content.body)")
        self.label?.text = "received something man"
    }

}
