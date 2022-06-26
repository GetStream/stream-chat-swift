//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest
import StreamChatTestHelpers

/// Mock implementation of `TokenRefreshFlow`
final class TokenRefreshFlow_Mock: TokenRefreshFlow {
    let connectionProvider: UserConnectionProvider
    
    init(connectionProvider: UserConnectionProvider) {
        self.connectionProvider = connectionProvider
    }
    
    lazy var mock_refresh = MockFunc.mock(for: refresh)
    
    func refresh(token: Token?, completion: @escaping TokenWaiter) {
        mock_refresh.call(with: (token, completion))
    }
}
