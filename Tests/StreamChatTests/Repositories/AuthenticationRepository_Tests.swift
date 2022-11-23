//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AuthenticationRepository_Tests: XCTestCase {
    private var repository: AuthenticationRepository!
    private var apiClient: APIClient_Spy!
    private var database: DatabaseContainer_Spy!
    private var clientUpdater: ChatClientUpdater_Mock!
    private var retryStrategy: RetryStrategy_Spy!

    override func setUp() {
        super.setUp()
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        let client = ChatClient_Mock(config: ChatClientConfig(apiKey: APIKey("")))
        clientUpdater = ChatClientUpdater_Mock(client: client)
        retryStrategy = RetryStrategy_Spy()
        repository = AuthenticationRepository(
            apiClient: apiClient,
            databaseContainer: database,
            clientUpdater: clientUpdater,
            tokenExpirationRetryStrategy: retryStrategy,
            timerType: DefaultTimer.self
        )
    }

    func test_concurrentAccess() {
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            _ = repository.currentUserId
        }
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            _ = repository.currentToken
        }
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            _ = repository.tokenProvider
        }
    }

    func test_currentUserId_isNil_whenNoPreviousSession() {
        XCTAssertNil(repository.currentUserId)
    }

    func test_currentUserId_isFetchedWhenInitializing() throws {
        let databaseUserId = "the-id"
        try database.createCurrentUser(id: databaseUserId)

        // Recreate repository to trigger init
        repository = AuthenticationRepository(
            apiClient: apiClient,
            databaseContainer: database,
            clientUpdater: clientUpdater,
            tokenExpirationRetryStrategy: retryStrategy,
            timerType: DefaultTimer.self
        )

        XCTAssertEqual(repository.currentUserId, databaseUserId)
    }

    func test_setToken_tokenIsUpdated() {
        XCTAssertNil(repository.currentToken)

        let newToken = Token.unique()

        repository.setToken(token: newToken)

        XCTAssertEqual(repository.currentToken, newToken)
    }

    func test_updatingToken_updatesUserId() throws {
        let databaseUserId = "the-id"
        try database.createCurrentUser(id: databaseUserId)

        // Recreate repository to trigger init
        repository = AuthenticationRepository(
            apiClient: apiClient,
            databaseContainer: database,
            clientUpdater: clientUpdater,
            tokenExpirationRetryStrategy: retryStrategy,
            timerType: DefaultTimer.self
        )

        XCTAssertEqual(repository.currentUserId, databaseUserId)

        // Update token

        let newUserId = "new-user-id"
        let token = Token.unique(userId: newUserId)
        repository.setToken(token: token)

        XCTAssertEqual(repository.currentUserId, newUserId)
    }

    // MARK: Connect user

    func test_connectUser_notGettingToken_callsClientUpdater_success() throws {
        let userInfo = UserInfo(id: "123")
        let completionExpectation = expectation(description: "Connect completion")

        var receivedError: Error?

        XCTAssertNil(repository.tokenProvider)

        repository.connectUser(userInfo: userInfo, tokenProvider: { _ in }, completion: { error in
            receivedError = error
            completionExpectation.fulfill()
        })

        XCTAssertNotNil(repository.tokenProvider)

        try XCTUnwrap(clientUpdater.reloadUserIfNeeded_completion)(nil)

        waitForExpectations(timeout: 0.1)

        XCTAssertNil(receivedError)
    }

    func test_connectUser_notGettingToken_callsClientUpdater_failure() throws {
        let userInfo = UserInfo(id: "123")
        let completionExpectation = expectation(description: "Connect completion")

        var receivedError: Error?

        XCTAssertNil(repository.tokenProvider)

        repository.connectUser(userInfo: userInfo, tokenProvider: { _ in }, completion: { error in
            receivedError = error
            completionExpectation.fulfill()
        })

        XCTAssertNotNil(repository.tokenProvider)

        let mockedError = ClientError("Test message")
        try XCTUnwrap(clientUpdater.reloadUserIfNeeded_completion)(mockedError)

        waitForExpectations(timeout: 0.1)

        XCTAssertEqual(receivedError as? ClientError, mockedError)
    }

    func test_connectUser_multipleTimes_callsChatClientUpdaterOnlyOnce_success() throws {
        let userInfo = UserInfo(id: "123")
        XCTAssertNil(repository.tokenProvider)

        var expectations: [XCTestExpectation] = []
        (1...4).forEach { _ in
            let completionExpectation = self.expectation(description: "Connect completion")
            repository.connectUser(userInfo: userInfo, tokenProvider: { _ in }, completion: { _ in
                completionExpectation.fulfill()
            })
            expectations.append(completionExpectation)
        }
        XCTAssertNotNil(repository.tokenProvider)
        XCTAssertEqual(expectations.count, 4)
        XCTAssertEqual(clientUpdater.reloadUserIfNeeded_callsCount, 1)

        try XCTUnwrap(clientUpdater.reloadUserIfNeeded_completion)(nil)

        waitForExpectations(timeout: 0.1)
    }

    func test_connectUser_updatesTokenProvider() throws {
        XCTAssertNil(repository.tokenProvider)
        let originalTokenProvider: TokenProvider = { _ in
            XCTFail("Should not be called")
        }
        repository.connectUser(userInfo: nil, tokenProvider: originalTokenProvider, completion: { _ in })
        XCTAssertNotNil(repository.tokenProvider)

        let expectation = self.expectation(description: "Correct token provider call")
        let newTokenProvider: TokenProvider = { _ in
            expectation.fulfill()
        }
        repository.connectUser(userInfo: nil, tokenProvider: newTokenProvider, completion: { _ in })

        // Simulate call to token provider
        try XCTUnwrap(repository.tokenProvider)({ _ in })
        waitForExpectations(timeout: 0.1)
    }

    func test_connectUser_clearsTokenCompletionsQueueAfterSuccess() throws {
        XCTAssertNil(repository.tokenProvider)
        let originalTokenProvider: TokenProvider = { _ in }

        var initialCompletionCalls = 0
        let expectation1 = expectation(description: "Completion call 1")
        repository.connectUser(
            userInfo: nil,
            tokenProvider: originalTokenProvider,
            completion: { _ in
                initialCompletionCalls += 1
                expectation1.fulfill()
            }
        )

        // Simulate call to token provider
        try XCTUnwrap(clientUpdater.reloadUserIfNeeded_completion)(nil)
        waitForExpectations(timeout: 0.1)

        XCTAssertNotNil(repository.tokenProvider)

        let expectation2 = expectation(description: "Completion call 2")
        let newTokenProvider: TokenProvider = { _ in }
        repository.connectUser(userInfo: nil, tokenProvider: newTokenProvider, completion: { _ in
            expectation2.fulfill()
        })

        // Simulate call to token provider
        try XCTUnwrap(clientUpdater.reloadUserIfNeeded_completion)(nil)
        waitForExpectations(timeout: 0.1)

        XCTAssertEqual(initialCompletionCalls, 1)
    }

    // MARK: Connect guest user

    func test_connectGuestUser_callsClientUpdater_success() throws {
        let userInfo = UserInfo(id: "123")
        let completionExpectation = expectation(description: "Connect completion")

        var receivedError: Error?

        XCTAssertNil(repository.tokenProvider)

        repository.connectGuestUser(userInfo: userInfo, completion: { error in
            receivedError = error
            completionExpectation.fulfill()
        })

        XCTAssertNotNil(repository.tokenProvider)

        try XCTUnwrap(clientUpdater.reloadUserIfNeeded_completion)(nil)

        waitForExpectations(timeout: 0.1)

        XCTAssertNil(receivedError)
    }

    func test_connectGuestUser_callsClientUpdater_failure() throws {
        let userInfo = UserInfo(id: "123")
        let completionExpectation = expectation(description: "Connect completion")

        var receivedError: Error?

        XCTAssertNil(repository.tokenProvider)

        repository.connectGuestUser(userInfo: userInfo, completion: { error in
            receivedError = error
            completionExpectation.fulfill()
        })

        XCTAssertNotNil(repository.tokenProvider)

        let mockedError = ClientError("Test message")
        try XCTUnwrap(clientUpdater.reloadUserIfNeeded_completion)(mockedError)

        waitForExpectations(timeout: 0.1)

        XCTAssertEqual(receivedError as? ClientError, mockedError)
    }

    func test_connectGuestUser_callsFetchGuestToken() throws {
        let userInfo = UserInfo(id: "123")
        repository.connectGuestUser(userInfo: userInfo, completion: { _ in })

        let tokenProvider = try XCTUnwrap(repository.tokenProvider)

        // Simulate call to token provider
        tokenProvider { _ in }

        let request = try XCTUnwrap(apiClient.request_endpoint)
        XCTAssertEqual(request.path, .guest)
    }

    // MARK: Clear Token Provider

    func test_clearTokenProvider_removesIt() {
        let userInfo = UserInfo(id: "123")
        repository.connectGuestUser(userInfo: userInfo, completion: { _ in })
        repository.setToken(token: .unique())
        XCTAssertNotNil(repository.tokenProvider)
        XCTAssertNotNil(repository.currentToken)
        XCTAssertNotNil(repository.currentUserId)

        repository.clearTokenProvider()
        XCTAssertNil(repository.tokenProvider)
        XCTAssertNotNil(repository.currentToken)
        XCTAssertNotNil(repository.currentUserId)
    }

    // MARK: Log out

    func test_logOut_clearsUserData() {
        let userInfo = UserInfo(id: "123")
        repository.connectGuestUser(userInfo: userInfo, completion: { _ in })
        repository.setToken(token: .unique())
        XCTAssertNotNil(repository.tokenProvider)
        XCTAssertNotNil(repository.currentToken)
        XCTAssertNotNil(repository.currentUserId)

        repository.logOutUser()
        XCTAssertNil(repository.tokenProvider)
        XCTAssertNil(repository.currentToken)
        XCTAssertNil(repository.currentUserId)
    }

    // MARK: Refresh token

    func test_refreshToken_returnsError_ifThereIsNoTokenProvider() {
        let expectation = self.expectation(description: "Refresh token")
        var receivedError: Error?
        repository.refreshToken { error in
            receivedError = error
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1)
        XCTAssertTrue(receivedError is ClientError.MissingTokenProvider)
    }

    func test_refreshToken_success() throws {
        try setTokenProvider(mockedResult: .success(.unique()))

        let receivedError = try refreshTokenAndWaitForResponse(mockedError: nil)

        XCTAssertCall("nextRetryDelay()", on: retryStrategy)
        XCTAssertCall("resetConsecutiveFailures()", on: retryStrategy)
        XCTAssertNil(receivedError)
    }

    func test_refreshToken_failure() throws {
        let mockedError = ClientError("Mocked error")
        try setTokenProvider(mockedResult: .failure(mockedError))

        let receivedError = try refreshTokenAndWaitForResponse(mockedError: mockedError)

        XCTAssertCall("nextRetryDelay()", on: retryStrategy)
        XCTAssertNotCall("resetConsecutiveFailures()", on: retryStrategy)
        XCTAssertEqual(receivedError, mockedError)
    }

    func test_refreshToken_multipleCalls_theoreticApproach() throws {
        try setTokenProvider(mockedResult: .success(.unique()))
        retryStrategy.mock_nextRetryDelay.returns(0.1)

        (1...3).forEach { _ in
            let expectation = self.expectation(description: "Refresh token")
            repository.refreshToken { _ in
                expectation.fulfill()
            }
        }

        AssertAsync.willBeTrue(clientUpdater.reloadUserIfNeeded_completion != nil)
        let reloadUserCompletion = try XCTUnwrap(clientUpdater.reloadUserIfNeeded_completion)
        let tokenProvider = try XCTUnwrap(clientUpdater.reloadUserIfNeeded_tokenProvider)
        reloadUserCompletion(nil)
        tokenProvider { _ in }

        waitForExpectations(timeout: 0.1)

        XCTAssertCall("nextRetryDelay()", on: retryStrategy, times: 3)
        XCTAssertCall("resetConsecutiveFailures()", on: retryStrategy, times: 1)
    }

    func test_refreshToken_multipleCalls_forcingRealisticDispatch() throws {
        try setTokenProvider(mockedResult: .success(.unique()))
        retryStrategy.mock_nextRetryDelay.returns(0)

        let expectation1 = expectation(description: "Refresh token")
        repository.refreshToken { _ in
            expectation1.fulfill()
        }

        retryStrategy.mock_nextRetryDelay.returns(0.1)

        DispatchQueue.main.async {
            (1...2).forEach { _ in
                let expectation = self.expectation(description: "Refresh token")
                self.repository.refreshToken { _ in
                    expectation.fulfill()
                }
            }
        }

        AssertAsync.willBeTrue(clientUpdater.reloadUserIfNeeded_completion != nil)
        let reloadUserCompletion = try XCTUnwrap(clientUpdater.reloadUserIfNeeded_completion)
        let tokenProvider = try XCTUnwrap(clientUpdater.reloadUserIfNeeded_tokenProvider)
        reloadUserCompletion(nil)
        tokenProvider { _ in }

        waitForExpectations(timeout: 0.1)

        XCTAssertCall("nextRetryDelay()", on: retryStrategy, times: 1)
        XCTAssertCall("resetConsecutiveFailures()", on: retryStrategy, times: 1)
    }

    private func refreshTokenAndWaitForResponse(mockedError: Error?) throws -> Error? {
        XCTAssertNotNil(repository.tokenProvider)
        retryStrategy.mock_nextRetryDelay.returns(0.1)

        let expectation = self.expectation(description: "Refresh token")
        var receivedError: Error?
        repository.refreshToken { error in
            receivedError = error
            expectation.fulfill()
        }

        AssertAsync.willBeTrue(clientUpdater.reloadUserIfNeeded_completion != nil)
        let reloadUserCompletion = try XCTUnwrap(clientUpdater.reloadUserIfNeeded_completion)
        let tokenProvider = try XCTUnwrap(clientUpdater.reloadUserIfNeeded_tokenProvider)
        reloadUserCompletion(mockedError)
        tokenProvider { _ in }
        waitForExpectations(timeout: 10)
        return receivedError
    }

    private func setTokenProvider(mockedResult: Result<Token, Error>) throws {
        let tokenProvider: TokenProvider = { $0(mockedResult) }
        repository.connectUser(userInfo: nil, tokenProvider: tokenProvider, completion: { _ in })
        try XCTUnwrap(clientUpdater.reloadUserIfNeeded_completion)(nil)
        clientUpdater.cleanUp()
    }
}
