//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class TokenHandler_Tests: XCTestCase {
    // MARK: - connectionProvider
    
    func test_connectionProvider_whenProviderForAnotherUserIsAssigned() throws {
        // GIVEN
        let currentUserId: UserId = .unique
        let token = Token.unique(userId: currentUserId)
        
        let sut = createTokenHandler()
        sut.connectionProvider = .initiated(userId: currentUserId) { _ in }
        sut.set(token: token) { _ in }
        
        var refreshTokenResult: Result<Token, Error>?
        sut.refreshToken { refreshTokenResult = $0 }
        
        var waiterResult: Result<Token, Error>?
        sut.add { waiterResult = $0 }
                
        // WHEN
        let anotherUserId: UserId = .unique
        sut.connectionProvider = .initiated(userId: anotherUserId) { _ in }
        
        // THEN
        XCTAssertNil(sut.refreshFlow)
        XCTAssertNil(sut.currentToken)
        XCTAssertTrue(
            [waiterResult, refreshTokenResult].allSatisfy {
                $0?.error is ClientError.UserDoesNotExist
            }
        )
    }
    
    func test_connectionProvider_whenThereIsNoCurrentUserAndProviderForNewUserIsAssigned() {
        // GIVEN
        let sut = createTokenHandler()
        sut.connectionProvider = .noCurrentUser
        
        var waiterCalled = false
        sut.add { _ in waiterCalled = true }
        
        // WHEN
        sut.connectionProvider = .initiated(userId: .unique) { _ in }
        
        // THEN
        XCTAssertFalse(waiterCalled)
    }
    
    // MARK: - refreshToken
    
    func test_refreshToken_whenCalledMultipleTime_onlyOneRefreshProcessIsTriggered() throws {
        // GIVEN
        let refreshFlowBuilderCalledOnce = expectation(description: "refreshFlowBuilder called")
        refreshFlowBuilderCalledOnce.assertForOverFulfill = true
        
        let sut = createTokenHandler {
            refreshFlowBuilderCalledOnce.fulfill()
            return TokenRefreshFlow_Mock(connectionProvider: $0)
        }
        
        // WHEN
        let iterations = 100
        
        var results = [Result<Token, Error>?](repeating: nil, count: iterations)

        let completionsCalled = XCTestExpectation(description: "refreshToken completions called")
        completionsCalled.expectedFulfillmentCount = iterations
        
        _ = log
        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            sut.refreshToken {
                results[index] = $0
                completionsCalled.fulfill()
            }
        }
        
        wait(for: [refreshFlowBuilderCalledOnce], timeout: defaultTimeout)
        
        let token = Token.unique()
        let refreshFlow = sut.mockRefeshFlow
        sut.mockRefeshFlow?.mock_refresh.calls.first?.1(.success(token))
        
        // THEN
        wait(for: [completionsCalled], timeout: defaultTimeout)
        XCTAssertTrue(results.allSatisfy { $0?.value == token })
        XCTAssertEqual(refreshFlow?.mock_refresh.calls.count, 1)
    }
    
    func test_refreshToken_whenRefreshSucceeds() {
        // GIVEN
        let userId: UserId = .unique
        
        let sut = createTokenHandler()
        sut.connectionProvider = .initiated(userId: userId) { _ in }
        
        var refreshResult: Result<Token, Error>?
        sut.refreshToken { refreshResult = $0 }
        
        XCTAssertEqual(sut.mockRefeshFlow?.connectionProvider, sut.connectionProvider)
        
        var tokenWaiterResult: Result<Token, Error>?
        sut.add { tokenWaiterResult = $0 }
    
        // WHEN
        let token = Token.unique(userId: userId)
        sut.mockRefeshFlow?.mock_refresh.calls.first?.1(.success(token))
        
        // THEN
        XCTAssertEqual(refreshResult?.value, token)
        XCTAssertEqual(tokenWaiterResult?.value, token)
        XCTAssertEqual(sut.currentToken, token)
        XCTAssertNil(sut.refreshFlow)
    }
    
    func test_refreshToken_whenRefreshFails() throws {
        // GIVEN
        let sut = createTokenHandler()
        sut.set(token: .unique(userId: .unique)) { _ in }
        
        var refreshResult: Result<Token, Error>?
        sut.refreshToken { refreshResult = $0 }
        
        XCTAssertEqual(sut.mockRefeshFlow?.connectionProvider, sut.connectionProvider)
        
        var tokenWaiterResult: Result<Token, Error>?
        sut.add { tokenWaiterResult = $0 }
        
        // WHEN
        let error = TestError()
        sut.mockRefeshFlow?.mock_refresh.calls.first?.1(.failure(error))
        
        // THEN
        XCTAssertEqual(refreshResult?.error as? TestError, error)
        XCTAssertEqual(tokenWaiterResult?.error as? TestError, error)
        XCTAssertNil(sut.currentToken)
        XCTAssertNil(sut.refreshFlow)
    }
    
    // MARK: - set(token: )
    
    func test_setToken_whenConnectionProviderIsMissing_assignesTokenAndCompletesWaiters() {
        // GIVEN
        let token = Token.unique(userId: .unique)
        
        let sut = createTokenHandler()
        sut.connectionProvider = .noCurrentUser
        
        var tokenWaiterResult: Result<Token, Error>?
        sut.add { tokenWaiterResult = $0 }
        
        // WHEN
        let completionCalled = XCTestExpectation(description: "set(token:) completion called")
        var completionError: Error?
        sut.set(token: token) { error in
            completionCalled.fulfill()
            completionError = error
        }
        
        // THEN
        wait(for: [completionCalled], timeout: defaultTimeout)
        XCTAssertEqual(tokenWaiterResult?.value, token)
        XCTAssertEqual(sut.currentToken, token)
        XCTAssertNil(completionError)
    }
    
    func test_setToken_whenConnectionProviderIsForSameUser_assignesTokenAndCompletesWaiters() {
        // GIVEN
        let token = Token.unique(userId: .unique)
        
        let sut = createTokenHandler()
        sut.connectionProvider = .notInitiated(userId: token.userId)
        
        var tokenWaiterResult: Result<Token, Error>?
        sut.add { tokenWaiterResult = $0 }
        
        // WHEN
        let completionCalled = XCTestExpectation(description: "set(token:) completion called")
        var completionError: Error?
        sut.set(token: token) { error in
            completionCalled.fulfill()
            completionError = error
        }
        
        // THEN
        wait(for: [completionCalled], timeout: defaultTimeout)
        XCTAssertNil(completionError)
        XCTAssertEqual(tokenWaiterResult?.value, token)
        XCTAssertEqual(sut.currentToken, token)
    }
    
    func test_setToken_whenConnectionProviderIsForAnotherUser_fails() {
        // GIVEN
        let sut = createTokenHandler()
        sut.connectionProvider = .notInitiated(userId: .unique)
        
        var tokenWaiterResult: Result<Token, Error>?
        sut.add { tokenWaiterResult = $0 }
        
        // WHEN
        let completionCalled = XCTestExpectation(description: "set(token:) completion called")
        var completionError: Error?
        sut.set(token: .unique(userId: .unique)) { error in
            completionCalled.fulfill()
            completionError = error
        }
        
        // THEN
        wait(for: [completionCalled], timeout: 0)
        XCTAssertTrue(completionError is ClientError.InvalidToken)
        XCTAssertNil(sut.currentToken)
        XCTAssertNil(tokenWaiterResult)
    }
    
    func test_setToken_whenRefreshFlowIsInProgress_refreshFlowIsCancelled() throws {
        // GIVEN
        let userId: UserId = .unique
        
        let sut = createTokenHandler()
        sut.connectionProvider = .initiated(userId: userId) { _ in }
        
        var tokenWaiterResult: Result<Token, Error>?
        sut.add { tokenWaiterResult = $0 }
        
        var refreshTokenResult: Result<Token, Error>?
        sut.refreshToken { refreshTokenResult = $0 }
        
        // WHEN
        let token: Token = .unique(userId: userId)
        sut.set(token: token) { _ in }
        
        // THEN
        XCTAssertEqual(tokenWaiterResult?.value, token)
        XCTAssertEqual(refreshTokenResult?.value, token)
        XCTAssertEqual(sut.currentToken, token)
        XCTAssertNil(sut.refreshFlow)
    }
    
    // MARK: - add(tokenWaiter:)
    
    func test_addTokenWaiter_whenTokenExistsAndNotBeingRefreshed_completesWaiterImmidiately() {
        // GIVEN
        let token: Token = .unique()
        
        let sut = createTokenHandler()
        sut.set(token: token) { _ in }
        
        // WHEN
        var waiterResult: Result<Token, Error>?
        sut.add { waiterResult = $0 }
        
        // THEN
        XCTAssertEqual(waiterResult?.value, token)
    }
    
    func test_addTokenWaiter_whenTokenDoesNotExist_storesWaiterToCallLater() {
        // GIVEN
        let sut = createTokenHandler()
        
        // WHEN
        var waiterIsCalled = false
        sut.add { _ in waiterIsCalled = true }
        
        // THEN
        XCTAssertFalse(waiterIsCalled)
    }
    
    func test_addTokenWaiter_whenTokenIsBeingRefreshed_storesWaiterToCallLater() {
        // GIVEN
        let token: Token = .unique()
        
        let sut = createTokenHandler()
        sut.connectionProvider = .initiated(userId: token.userId) { _ in }
        sut.set(token: token) { _ in }
        sut.refreshToken { _ in }
        
        // WHEN
        var waiterIsCalled = false
        sut.add { _ in waiterIsCalled = true }
        
        // THEN
        XCTAssertFalse(waiterIsCalled)
    }
    
    func test_addTokenWaiter_doesNotTriggerRefreshProcess() {
        // GIVEN
        let sut = createTokenHandler()
        sut.connectionProvider = .initiated(userId: .unique) { _ in }
        
        // WHEN
        sut.add { _ in }
        sut.add { _ in }
        sut.add { _ in }
        
        // THEN
        XCTAssertNil(sut.refreshFlow)
    }
    
    // MARK: - removeTokenWaiter
    
    func test_removeTokenWaiter_waiterIsNotCalledWhenTokenIsSet() {
        // GIVEN
        let sut = createTokenHandler()
        
        var waiterCalled = false
        let token = sut.add { _ in waiterCalled = true }
        
        // WHEN
        sut.removeTokenWaiter(token)
        sut.set(token: .unique()) { _ in }
        
        // THEN
        XCTAssertFalse(waiterCalled)
    }
    
    func test_removeTokenWaiter_waiterIsNotCalledWhenTokenIsRefreshed() throws {
        // GIVEN
        let sut = createTokenHandler()
        
        let token = Token.unique()
        sut.connectionProvider = .initiated(userId: token.userId) { _ in }
        
        var waiterCalled = false
        let waiterToken = sut.add { _ in waiterCalled = true }
        
        // WHEN
        let refreshCompletionCalled = XCTestExpectation(description: "completion called")
        sut.refreshToken { _ in refreshCompletionCalled.fulfill() }
        
        sut.removeTokenWaiter(waiterToken)
        
        let refreshCompletion = try XCTUnwrap(sut.mockRefeshFlow?.mock_refresh.calls.first?.1)
        refreshCompletion(.success(.unique(userId: token.userId)))
        
        // THEN
        wait(for: [refreshCompletionCalled], timeout: defaultTimeout)
        XCTAssertFalse(waiterCalled)
    }
    
    // MARK: - cancelRefreshFlow
    
    func test_cancelRefreshFlow_cancelsWaitersWithTheGivenError() {
        // GIVEN
        let sut = createTokenHandler()
        
        let waitersCount = 5
        var tokenWaiterResults: [Result<Token, Error>] = []
        (0..<waitersCount).forEach { _ in
            sut.add { tokenWaiterResults.append($0) }
        }
        
        // WHEN
        let error = TestError()
        sut.cancelRefreshFlow(with: error)
        
        // THEN
        XCTAssertEqual(tokenWaiterResults.count, waitersCount)
        XCTAssertTrue(
            tokenWaiterResults.allSatisfy {
                $0.error as? TestError == error
            }
        )
    }
    
    func test_cancelRefreshFlow_removesWaiters() {
        // GIVEN
        let sut = createTokenHandler()
        
        var waiterCallsCount = 0
        sut.add { _ in waiterCallsCount += 1 }
        sut.cancelRefreshFlow(with: TestError())
        XCTAssertEqual(waiterCallsCount, 1)
        
        // WHEN
        sut.cancelRefreshFlow(with: TestError())
        sut.cancelRefreshFlow(with: TestError())
        sut.cancelRefreshFlow(with: TestError())

        // THEN
        XCTAssertEqual(waiterCallsCount, 1)
    }
    
    func test_cancelRefreshFlow_doesNotResetTheToken() {
        // GIVEN
        let token: Token = .unique()
        let sut = createTokenHandler()
        sut.set(token: token) { _ in }
        
        // WHEN
        sut.cancelRefreshFlow(with: TestError())
        
        // THEN
        XCTAssertEqual(sut.currentToken, token)
    }
    
    // MARK: - deinit
    
    func test_tokenHandler_whenDeallocated_cancelsTokenWaiters() throws {
        // GIVEN
        var sut: DefaultTokenHandler? = createTokenHandler()
        
        let waitersCount = 5
        var tokenWaiterResults: [Result<Token, Error>] = []
        (0..<waitersCount).forEach { _ in
            sut?.add { tokenWaiterResults.append($0) }
        }
        
        // WHEN
        sut = nil
        
        // THEN
        XCTAssertEqual(tokenWaiterResults.count, waitersCount)
        XCTAssertTrue(
            tokenWaiterResults.allSatisfy {
                $0.error is ClientError.ClientHasBeenDeallocated
            }
        )
    }
    
    // MARK: - Private
    
    private func createTokenHandler(
        refreshFlowBuilder: @escaping DefaultTokenHandler.TokenRefreshFlowBuilder = TokenRefreshFlow_Mock.init
    ) -> DefaultTokenHandler {
        .init(refreshFlowBuilder: refreshFlowBuilder)
    }
}

private extension DefaultTokenHandler {
    var mockRefeshFlow: TokenRefreshFlow_Mock? {
        refreshFlow.map { $0 as! TokenRefreshFlow_Mock }
    }
}
