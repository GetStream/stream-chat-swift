//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat

/// Mock implementation of `ChatClientUpdater`
final class ChatClientUpdater_Mock: ChatClientUpdater {
    @Atomic var prepareEnvironment_newToken: Token?
    var prepareEnvironment_called: Bool { prepareEnvironment_newToken != nil }

    @Atomic var reloadUserIfNeeded_called = false {
        didSet {
            reloadUserIfNeeded_callsCount += 1
        }
    }

    var reloadUserIfNeeded_callsCount = 0
    @Atomic var reloadUserIfNeeded_completion: ((Error?) -> Void)?
    @Atomic var reloadUserIfNeeded_callSuper: (() -> Void)?
    @Atomic var reloadUserIfNeeded_userConnectionProvider: UserConnectionProvider?

    @Atomic var connect_called = false
    @Atomic var connect_completion: ((Error?) -> Void)?

    @Atomic var disconnect_called = false
    @Atomic var disconnect_source: WebSocketConnectionState.DisconnectionSource?

    // MARK: - Overrides

    override func prepareEnvironment(
        userInfo: UserInfo?,
        newToken: Token,
        completion: ((Error?) -> Void)? = nil
    ) {
        prepareEnvironment_newToken = newToken
    }

    override func reloadUserIfNeeded(
        userInfo: UserInfo?,
        userConnectionProvider: UserConnectionProvider?,
        completion: ((Error?) -> Void)?
    ) {
        reloadUserIfNeeded_called = true
        reloadUserIfNeeded_completion = completion
        reloadUserIfNeeded_userConnectionProvider = userConnectionProvider
        reloadUserIfNeeded_callSuper = {
            super.reloadUserIfNeeded(
                userInfo: userInfo,
                userConnectionProvider: userConnectionProvider,
                completion: completion
            )
        }
    }

    override func connect(
        userInfo: UserInfo?,
        completion: ((Error?) -> Void)? = nil
    ) {
        connect_called = true
        connect_completion = completion
    }

    override func disconnect(source: WebSocketConnectionState.DisconnectionSource = .userInitiated) {
        disconnect_called = true
        disconnect_source = source
    }

    // MARK: - Clean Up

    func cleanUp() {
        prepareEnvironment_newToken = nil

        reloadUserIfNeeded_called = false
        reloadUserIfNeeded_callsCount = 0
        reloadUserIfNeeded_completion = nil
        reloadUserIfNeeded_callSuper = nil

        connect_called = false
        connect_completion = nil

        disconnect_called = false
    }
}
