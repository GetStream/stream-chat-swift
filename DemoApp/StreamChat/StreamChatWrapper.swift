//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI
import UserNotifications

extension ChatClient {
    static var shared: ChatClient!
}

final class StreamChatWrapper {
    static let shared = StreamChatWrapper()

    // ChatClient config
    var config: ChatClientConfig = {
        var config = ChatClientConfig(apiKeyString: apiKeyString)
        config.shouldShowShadowedMessages = true
        config.applicationGroupIdentifier = applicationGroupIdentifier
        return config
    }()

    private var client: ChatClient {
        ChatClient.shared
    }

    func setUpChat() {
        guard ChatClient.shared == nil else { return }

        // Set the log level
        LogConfig.level = .warning
        LogConfig.formatters = [
            PrefixLogFormatter(prefixes: [.info: "ℹ️", .debug: "🛠", .warning: "⚠️", .error: "🚨"])
        ]

        // Create Client
        ChatClient.shared = ChatClient(config: config)

        // Customize UI
        configureUI()

        // L10N
        let localizationProvider = Appearance.default.localizationProvider
        Appearance.default.localizationProvider = { key, table in
            let localizedString = localizationProvider(key, table)

            return localizedString == key
                ? Bundle.main.localizedString(forKey: key, value: nil, table: table)
                : localizedString
        }
    }

    func configureUI() {
        // Customize UI
        Components.default.messageListDateSeparatorEnabled = true
        Components.default.messageListDateOverlayEnabled = true

        // Customize UI components
        Components.default.channelListRouter = DemoChatChannelListRouter.self
        Components.default.channelVC = DemoChatChannelVC.self
        Components.default.messageContentView = DemoChatMessageContentView.self
        Components.default.messageActionsVC = DemoChatMessageActionsVC.self
        Components.default.reactionsSorting = { $0.type.position < $1.type.position }
    }
}

extension StreamChatWrapper {
    func setMessageDiffingEnabled(_ isEnabled: Bool) {
        Components.default._messageListDiffingEnabled = isEnabled
    }
}

// MARK: User Authentication

extension StreamChatWrapper {
    func connect(user: DemoUserType, completion: @escaping (Error?) -> Void) {
        switch user {
        case let .credentials(userCredentials):
            client.connectUser(
                userInfo: userCredentials.userInfo,
                token: userCredentials.token,
                completion: completion
            )
        case let .guest(userId):
            client.connectGuestUser(userInfo: .init(id: userId), completion: completion)
        case .anonymous:
            client.connectAnonymousUser(completion: completion)
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
                self?.setupRemoteNotifications()
            }
        }
    }

    func logOut() {
        let currentUserController = client.currentUserController()
        if let deviceId = currentUserController.currentUser?.currentDevice?.id {
            currentUserController.removeDevice(id: deviceId) { error in
                if let error = error {
                    log.warning("removing the device failed with an error \(error)")
                }
            }
        }

        client.disconnect()
        ChatClient.shared = nil
    }
}

// MARK: Push Notifications

extension StreamChatWrapper {
    func setupRemoteNotifications() {
        PushNotifications.shared.registerForPushNotifications()
    }

    func registerForPushNotifications(with deviceToken: Data) {
        client.currentUserController().addDevice(.apn(token: deviceToken)) {
            if let error = $0 {
                log.error("adding a device failed with an error \(error)")
            }
        }
    }

    func notificationInfo(for response: UNNotificationResponse) -> ChatPushNotificationInfo? {
        try? ChatPushNotificationInfo(content: response.notification.request.content)
    }
}
