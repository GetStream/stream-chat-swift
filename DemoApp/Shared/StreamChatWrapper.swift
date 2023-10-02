//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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
        config.urlSessionConfiguration.httpAdditionalHeaders = ["Custom": "Example"]
        return config
    }()

    private init() {
        configureUI()
    }
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
            let userInfo = UserInfo(
                id: userCredentials.userInfo.id,
                name: userCredentials.userInfo.name,
                imageURL: userCredentials.userInfo.imageURL,
                isInvisible: UserConfig.shared.isInvisible,
                extraData: userCredentials.userInfo.extraData
            )
            guard AppConfig.shared.demoAppConfig.isTokenRefreshEnabled else {
                client?.connectUser(
                    userInfo: userInfo,
                    token: userCredentials.token,
                    completion: completion
                )
                return
            }
            client?.connectUser(
                userInfo: userInfo,
                tokenProvider: refreshingTokenProvider(initialToken: userCredentials.token, tokenDurationInMinutes: 60),
                completion: completion
            )
        case let .guest(userId):
            client?.connectGuestUser(userInfo: .init(id: userId), completion: completion)
        case .anonymous:
            client?.connectAnonymousUser(completion: completion)
        }
    }

    func logIn(as user: DemoUserType, completion: @escaping (Error?) -> Void) {
        // Setup Stream Chat
        setUpChat()

        // We connect from a background thread to make sure it works without issues/crashes.
        // This is for testing purposes only. As a customer you can connect directly without dispatching to any queue.
        DispatchQueue.global().async {
            self.connect(user: user) { [weak self] error in
                if let error = error {
                    log.warning(error.localizedDescription)
                } else {
                    self?.onRemotePushRegistration?()
                }
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }

    func logOut(completion: @escaping () -> Void) {
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

        client.logout(completion: completion)

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
