//
//  AuthenticationRepository_Mock.swift
//  StreamChatTestTools
//
//  Created by Pol Quintana on 17/10/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatTestHelpers
@testable import StreamChat

class AuthenticationRepository_Mock: AuthenticationRepository, Spy {
    var recordedFunctions: [String] = []
    var mockedToken: Token?
    var mockedCurrentUserId: UserId?
    var refreshTokenError: Error?

    override var currentUserId: UserId? {
        return mockedCurrentUserId ?? super.currentUserId
    }

    override var currentToken: Token? {
        return mockedToken ?? super.currentToken
    }

    override init(apiClient: APIClient,
                  databaseContainer: DatabaseContainer,
                  clientUpdater: ChatClientUpdater,
                  tokenExpirationRetryStrategy: RetryStrategy = DefaultRetryStrategy(),
                  timerType: StreamChat.Timer.Type = DefaultTimer.self) {
        super.init(apiClient: apiClient,
                   databaseContainer: databaseContainer,
                   clientUpdater: clientUpdater,
                   tokenExpirationRetryStrategy: tokenExpirationRetryStrategy,
                   timerType: timerType)
    }

    override func refreshToken(completion: @escaping (Error?) -> Void) {
        record()
        completion(refreshTokenError)
    }

    override func connectUser(with userInfo: UserInfo?, tokenProvider: @escaping TokenProvider, completion: @escaping (Error?) -> Void) {
        record()
        super.connectUser(with: userInfo, tokenProvider: tokenProvider, completion: completion)
    }

    override func connectGuestUser(userInfo: UserInfo, completion: @escaping (Error?) -> Void) {
        record()
        super.connectGuestUser(userInfo: userInfo, completion: completion)
    }
}
