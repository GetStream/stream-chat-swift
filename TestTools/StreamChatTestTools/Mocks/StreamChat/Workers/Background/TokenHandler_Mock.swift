//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of `TokenHandler`
final class TokenHandler_Mock: TokenHandler {
    var currentToken: Token?
    
    var connectionProvider: UserConnectionProvider
    
    init(connectionProvider: UserConnectionProvider = .noCurrentUser) {
        self.connectionProvider = connectionProvider
    }
    
    lazy var mock_setToken = MockFunc.mock(for: `set`)

    func set(token: Token, completion: ((Error?) -> Void)?) {
        mock_setToken.call(with: (token, completion))
    }
    
    lazy var mock_refreshToken = MockFunc.mock(for: refreshToken)
    
    func refreshToken(completion: @escaping TokenWaiter) {
        mock_refreshToken.call(with: completion)
    }
    
    lazy var mock_addTokenWaiter = MockFunc.mock(for: add)
    
    func add(tokenWaiter: @escaping TokenWaiter) -> WaiterToken {
        mock_addTokenWaiter.callAndReturn(tokenWaiter)
    }
    
    lazy var mock_removeTokenWaiter = MockFunc.mock(for: removeTokenWaiter)
    
    func removeTokenWaiter(_ token: WaiterToken) {
        mock_removeTokenWaiter.call(with: token)
    }
    
    lazy var mock_cancelRefreshFlow = MockFunc.mock(for: cancelRefreshFlow)
    
    func cancelRefreshFlow(with error: Error) {
        mock_cancelRefreshFlow.call(with: error)
    }
}

extension UserConnectionProvider: Equatable {
    public static func == (lhs: UserConnectionProvider, rhs: UserConnectionProvider) -> Bool {
        switch (lhs, rhs) {
        case (.noCurrentUser, .noCurrentUser):
            return true
        case (.notInitiated(let id1), .notInitiated(let id2)) where id1 == id2:
            return true
        case (.initiated(let id1, _), .initiated(let id2, _)) where id1 == id2:
            return true
        default:
            return false
        }
    }
}
