//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class TokenRefreshFlow_Tests: XCTestCase {
    var mockRetryStrategy: RetryStrategy_Spy!
    var mockTime: VirtualTime { VirtualTimeTimer.time }
        
    // MARK: - setUp, tearDown
    
    override func setUp() {
        super.setUp()
        
        mockRetryStrategy = .init()
        VirtualTimeTimer.time = .init()
    }
    
    override func tearDown() {
        VirtualTimeTimer.time = nil
        mockRetryStrategy = nil
        
        super.tearDown()
    }
    
    // MARK: - refresh
    
    func test_refreshToken_whenTheSameTokenIsReturned() {
        // GIVEN
        let userId: UserId = .unique
        let token = Token.unique(userId: userId)
        
        let sut = createRefreshFlow(
            connectionProvider: .initiated(userId: userId) {
                $0(.success(token))
            }
        )
        
        // WHEN
        var refreshResult: Result<Token, Error>?
        sut.refresh(token: token) { refreshResult = $0 }
        mockTime.run()
        
        // THEN
        XCTAssertTrue(refreshResult?.error is ClientError.InvalidToken)
    }
    
    func test_refreshToken_whenExpiredTokenIsReturned() {
        // GIVEN
        let userId: UserId = .unique
        
        let sut = createRefreshFlow(
            connectionProvider: .initiated(userId: userId) { completion in
                let expiredToken = Token.expired(userId: userId)
                
                completion(.success(expiredToken))
            }
        )
                
        // WHEN
        var refreshResult: Result<Token, Error>?
        sut.refresh(token: .unique(userId: userId)) { refreshResult = $0 }
        mockTime.run()
        
        // THEN
        XCTAssertTrue(refreshResult?.error is ClientError.ExpiredToken)
    }
    
    func test_refreshToken_whenTokenForAnotherUserIsReturned() {
        // GIVEN
        let userId: UserId = .unique

        let sut = createRefreshFlow(
            connectionProvider: .initiated(userId: userId) { completion in
                let anotherUserId: UserId = .unique
                
                completion(.success(.unique(userId: anotherUserId)))
            }
        )
                
        // WHEN
        var refreshResult: Result<Token, Error>?
        sut.refresh(token: .unique(userId: userId)) { refreshResult = $0 }
        mockTime.run()
        
        // THEN
        XCTAssertTrue(refreshResult?.error is ClientError.InvalidToken)
    }
    
    func test_refreshToken_whenAllRetryAttempsFail() {
        // GIVEN
        let userId: UserId = .unique
        let expiredToken: Token = .expired(userId: userId)

        var connectionProviderCallsCount = 0
        let sut = createRefreshFlow(
            connectionProvider: .initiated(userId: userId) { [mockRetryStrategy] completion in
                mockRetryStrategy!.consecutiveFailuresCount += 1
                connectionProviderCallsCount += 1
                completion(.failure(TestError()))
            },
            maximumTokenRefreshAttempts: 3
        )
        
        // WHEN
        var refreshResult: Result<Token, Error>?
        sut.refresh(token: expiredToken) { refreshResult = $0 }
        
        XCTAssertNil(refreshResult)
        XCTAssertEqual(connectionProviderCallsCount, 0)
        mockRetryStrategy.mock_nextRetryDelay.returns(2)
        mockTime.run(numberOfSeconds: 1)
        
        XCTAssertNil(refreshResult)
        XCTAssertEqual(connectionProviderCallsCount, 1)
        mockRetryStrategy.mock_nextRetryDelay.returns(5)
        mockTime.run(numberOfSeconds: 2)

        XCTAssertNil(refreshResult)
        XCTAssertEqual(connectionProviderCallsCount, 2)
        mockRetryStrategy.mock_nextRetryDelay.returns(10)
        mockTime.run()
        
        // THEN
        XCTAssertTrue(refreshResult?.error is ClientError.TooManyTokenRefreshAttempts)
        XCTAssertEqual(connectionProviderCallsCount, 3)
    }
    
    func test_refreshToken_whenRefreshAttemptTimesOut() {
        // GIVEN
        let userId: UserId = .unique
        
        let connectionProviderCalledOnce = expectation(description: "connectionProvider called once")
        connectionProviderCalledOnce.assertForOverFulfill = false
        
        let connectionProviderCalledTwice = expectation(description: "connectionProvider called twice")
        connectionProviderCalledTwice.expectedFulfillmentCount = 2
        
        var connectionProviderCompletions = [TokenWaiter]()
        
        let sut = createRefreshFlow(
            connectionProvider: .initiated(userId: userId) {
                connectionProviderCompletions.append($0)
                connectionProviderCalledOnce.fulfill()
                connectionProviderCalledTwice.fulfill()
            },
            attemptTimeout: 5
        )
        
        // WHEN
        var refreshResult: Result<Token, Error>?
        sut.refresh(token: .expired(userId: userId)) {
            refreshResult = $0
        }
        
        mockTime.run(numberOfSeconds: 0.1)
        wait(for: [connectionProviderCalledOnce], timeout: defaultTimeout)
        mockTime.run(numberOfSeconds: 10)
        
        mockTime.run(numberOfSeconds: 1)
        
        // THEN
        wait(for: [connectionProviderCalledTwice], timeout: defaultTimeout)
        XCTAssertTrue(mockRetryStrategy.mock_incrementConsecutiveFailures.called)
        
        // WHEN
        let delayedToken = Token.unique(userId: userId)
        connectionProviderCompletions.first?(.success(delayedToken))

        // THEN
        XCTAssertNil(refreshResult)
    }
    
    // MARK: - deinit
    
    func test_whenResultComesAfterFlowIsDeallocated_resultIsIgnored() {
        // GIVEN
        let userId: UserId = .unique
        
        var connectionProviderCompletion: TokenWaiter?
        let connectionProviderCalled = expectation(description: "connectionProvider called")
        var sut: DefaultTokenRefreshFlow? = createRefreshFlow(
            connectionProvider: .initiated(userId: userId) {
                connectionProviderCompletion = $0
                connectionProviderCalled.fulfill()
            }
        )
        
        var refreshResult: Result<Token, Error>?
        sut?.refresh(token: .expired(userId: userId)) { refreshResult = $0 }
        mockTime.run()
        wait(for: [connectionProviderCalled], timeout: defaultTimeout)
        
        // WHEN
        sut = nil
        connectionProviderCompletion?(.success(.unique(userId: userId)))

        // THEN
        XCTAssertNil(refreshResult)
    }
    
    // MARK: - Private
    
    private func createRefreshFlow(
        connectionProvider: UserConnectionProvider,
        maximumTokenRefreshAttempts: Int = 10,
        attemptTimeout: TimeInterval = 10
    ) -> DefaultTokenRefreshFlow {
        .init(
            tokenProvider: connectionProvider,
            maximumTokenRefreshAttempts: maximumTokenRefreshAttempts,
            attemptTimeout: attemptTimeout,
            retryStrategy: mockRetryStrategy,
            timerType: VirtualTimeTimer.self
        )
    }
}
