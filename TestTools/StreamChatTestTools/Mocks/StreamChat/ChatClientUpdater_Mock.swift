//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat

/// Mock implementation of `ChatClientUpdater`
final class ChatClientUpdater_Mock: ChatClientUpdater {
    @Atomic var reloadUserIfNeeded_called = false {
        didSet {
            reloadUserIfNeeded_callsCount += 1
        }
    }

    var reloadUserIfNeeded_callsCount = 0
    @Atomic var reloadUserIfNeeded_tokenProvider: TokenProvider?
    @Atomic var reloadUserIfNeeded_completion: ((Error?) -> Void)?
    @Atomic var reloadUserIfNeeded_callSuper: (() -> Void)?

    @Atomic var connect_called = false
    @Atomic var connect_completion: ((Error?) -> Void)?

    var disconnect_called: Bool { disconnect_source != nil }
    @Atomic var disconnect_source: WebSocketConnectionState.DisconnectionSource?
    @Atomic var disconnect_completion: (() -> Void)?

    // MARK: - Overrides

    override func reloadUserIfNeeded(
        userInfo: UserInfo?,
        tokenProvider: TokenProvider?,
        completion: ((Error?) -> Void)?
    ) {
        reloadUserIfNeeded_called = true
        reloadUserIfNeeded_tokenProvider = tokenProvider
        reloadUserIfNeeded_completion = completion
        reloadUserIfNeeded_callSuper = {
            super.reloadUserIfNeeded(
                userInfo: userInfo,
                tokenProvider: tokenProvider,
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
    
    override func disconnect(
        source: WebSocketConnectionState.DisconnectionSource = .userInitiated,
        completion: @escaping () -> Void
    ) {
        disconnect_source = source
        disconnect_completion = completion
    }

    // MARK: - Clean Up

    func cleanUp() {
        reloadUserIfNeeded_called = false
        reloadUserIfNeeded_callsCount = 0
        reloadUserIfNeeded_tokenProvider = nil
        reloadUserIfNeeded_completion = nil
        reloadUserIfNeeded_callSuper = nil

        connect_called = false
        connect_completion = nil

        disconnect_source = nil
        disconnect_completion = nil
    }
}
