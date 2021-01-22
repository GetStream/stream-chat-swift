//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of `ChatClientUpdater`
class ChatClientUpdaterMock<ExtraData: ExtraDataTypes>: ChatClientUpdater<ExtraData> {
    @Atomic var prepareEnvironment_newToken: Token?
    var prepareEnvironment_called: Bool { prepareEnvironment_newToken != nil }

    @Atomic var reloadUserIfNeeded_called = false
    @Atomic var reloadUserIfNeeded_completion: ((Error?) -> Void)?
    @Atomic var reloadUserIfNeeded_callSuper: (() -> Void)?

    @Atomic var connect_called = false
    @Atomic var connect_completion: ((Error?) -> Void)?

    @Atomic var disconnect_called = false

    // MARK: - Overrides

    override func prepareEnvironment(newToken: Token) throws {
        prepareEnvironment_newToken = newToken
    }

    override func reloadUserIfNeeded(completion: ((Error?) -> Void)?) {
        reloadUserIfNeeded_called = true
        reloadUserIfNeeded_completion = completion
        reloadUserIfNeeded_callSuper = {
            super.reloadUserIfNeeded(completion: completion)
        }
    }

    override func connect(completion: ((Error?) -> Void)? = nil) {
        connect_called = true
        connect_completion = completion
    }

    override func disconnect() {
        disconnect_called = true
    }

    // MARK: - Clean Up

    func cleanUp() {
        prepareEnvironment_newToken = nil

        reloadUserIfNeeded_called = false
        reloadUserIfNeeded_completion = nil
        reloadUserIfNeeded_callSuper = nil

        connect_called = false
        connect_completion = nil

        disconnect_called = false
    }
}
