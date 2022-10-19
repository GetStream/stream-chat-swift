//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI
import UserNotifications

final class StreamChatWrapper {
    static let shared = StreamChatWrapper()

    // This closure is called once the SDK is ready to register for remote push notifications
    var onRemotePushRegistration: (() -> Void)?

    // Chat client
    var client: ChatClient?

    // ChatClient config
    var config: ChatClientConfig = {
        var config = ChatClientConfig(apiKeyString: apiKeyString)
        config.shouldShowShadowedMessages = true
        config.applicationGroupIdentifier = applicationGroupIdentifier
        return config
    }()

    private init() {}
}

extension StreamChatWrapper {
    // Client not instantiated
    private func logClientNotInstantiated() {
        guard client != nil else {
            print("⚠️ Chat client is not instantiated")
            return
        }
    }
}

// MARK: User Authentication

extension StreamChatWrapper {
    func connect(user: DemoUserType, completion: @escaping (Error?) -> Void) {
        switch user {
        case let .credentials(userCredentials):
            client?.connectUser(
                userInfo: userCredentials.userInfo,
                token: userCredentials.token,
                completion: completion
            )
        case let .guest(userId):
            client?.connectGuestUser(userInfo: .init(id: userId), completion: completion)
        case .anonymous:
            client?.connectAnonymousUser(completion: completion)
        }
    }

    func logIn(as user: DemoUserType) {
        // Setup Stream Chat
        setUpChat()

        // Connect to chat
        connect(user: user) { [weak self] in
            if let error = $0 {
                log.warning(error.localizedDescription)
            } else {
                self?.onRemotePushRegistration?()
            }
        }
    }

    func logOut() {
        guard let client = self.client else {
            logClientNotInstantiated()
            return
        }
        let currentUserController = client.currentUserController()
        if let deviceId = currentUserController.currentUser?.currentDevice?.id {
            currentUserController.removeDevice(id: deviceId) { error in
                if let error = error {
                    log.warning("removing the device failed with an error \(error)")
                }
            }
        }

        client.logout()
        
        self.client = nil
    }
}

// MARK: Controllers

extension StreamChatWrapper {
    func channelController(for channelId: ChannelId?) -> ChatChannelController? {
        guard let client = self.client else {
            logClientNotInstantiated()
            return nil
        }
        return channelId.map { client.channelController(for: $0) }
    }

    func channelListController(query: ChannelListQuery) -> ChatChannelListController? {
        client?.channelListController(query: query)
    }

    func messageController(cid: ChannelId, messageId: MessageId) -> ChatMessageController? {
        client?.messageController(cid: cid, messageId: messageId)
    }
}

// MARK: Push Notifications

extension StreamChatWrapper {
    func registerForPushNotifications(with deviceToken: Data) {
        client?.currentUserController().addDevice(.apn(token: deviceToken, providerName: Bundle.pushProviderName)) {
            if let error = $0 {
                log.error("adding a device failed with an error \(error)")
            }
        }
    }

    func notificationInfo(for response: UNNotificationResponse) -> ChatPushNotificationInfo? {
        try? ChatPushNotificationInfo(content: response.notification.request.content)
    }
}
