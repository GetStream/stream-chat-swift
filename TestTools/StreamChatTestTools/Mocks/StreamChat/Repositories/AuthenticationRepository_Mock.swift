//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatTestHelpers
@testable import StreamChat

class AuthenticationRepository_Mock: AuthenticationRepository, Spy {
    enum Signature {
        static let connectTokenProvider = "connectUser(userInfo:tokenProvider:completion:)"
        static let connectGuest = "connectGuestUser(userInfo:completion:)"
        static let refreshToken = "refreshToken(completion:)"
        static let clearTokenProvider = "clearTokenProvider()"
        static let logOut = "logOutUser()"
        static let completeTokenWaiters = "completeTokenWaiters(token:)"
        static let setToken = "setToken(token:completeTokenWaiters:)"
        static let provideToken = "provideToken(timeout:completion:)"
    }

    var recordedFunctions: [String] = []
    var mockedToken: Token?
    var mockedCurrentUserId: UserId?

    var connectUserResult: Result<Void, Error>?
    var connectGuestResult: Result<Void, Error>?
    var refreshTokenResult: Result<Void, Error>?
    var completeWaitersToken: Token?

    override var currentUserId: UserId? {
        return mockedCurrentUserId
    }

    override var currentToken: Token? {
        return mockedToken
    }

    override init(apiClient: APIClient,
                  databaseContainer: DatabaseContainer,
                  connectionRepository: ConnectionRepository,
                  tokenExpirationRetryStrategy: RetryStrategy = DefaultRetryStrategy(),
                  timerType: StreamChat.Timer.Type = DefaultTimer.self) {
        // This is just to avoid private `fetchCurrentUser` method from crashing
        do {
            try databaseContainer.createCurrentUser()
            (databaseContainer as? DatabaseContainer_Spy)?.clear()
        } catch {
            log.assertionFailure("Should be able to create a user")
        }

        super.init(apiClient: apiClient,
                   databaseContainer: databaseContainer,
                   connectionRepository: connectionRepository,
                   tokenExpirationRetryStrategy: tokenExpirationRetryStrategy,
                   timerType: timerType)
    }

    override func refreshToken(completion: @escaping (Error?) -> Void) {
        record()
        if let result = refreshTokenResult {
            completion(result.error)
        }
    }

    override func connectUser(userInfo: UserInfo?, tokenProvider: @escaping TokenProvider, completion: @escaping (Error?) -> Void) {
        record()
        if let result = connectUserResult {
            completion(result.error)
        }
    }

    override func connectGuestUser(userInfo: UserInfo, completion: @escaping (Error?) -> Void) {
        record()
        if let result = connectGuestResult {
            completion(result.error)
        }
    }

    override func setToken(token: Token, completeTokenWaiters: Bool) {
        record()
        setMockToken(token)
    }

    override func clearTokenProvider() {
        record()
    }

    override func logOutUser() {
        record()
    }

    override func completeTokenWaiters(token: Token?) {
        record()
        completeWaitersToken = token
    }

    override func provideToken(timeout: TimeInterval = 10, completion: @escaping (Result<Token, Error>) -> Void) {
        record()
    }
}

extension AuthenticationRepository {
    func setMockToken(_ token: Token = Token.unique()) {
        guard let mock = self as? AuthenticationRepository_Mock else {
            assertionFailure()
            return
        }

        mock.mockedToken = token
        mock.mockedCurrentUserId = token.userId
    }
}
