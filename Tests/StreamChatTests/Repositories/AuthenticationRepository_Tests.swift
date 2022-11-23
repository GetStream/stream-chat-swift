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
    private var connectionRepository: ConnectionRepository_Mock!
    private var retryStrategy: RetryStrategy_Spy!

    override func setUp() {
        super.setUp()
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        let client = ChatClient_Mock(config: ChatClientConfig(apiKey: APIKey("")))
        connectionRepository = ConnectionRepository_Mock(client: client)
        retryStrategy = RetryStrategy_Spy()
        repository = AuthenticationRepository(
            apiClient: apiClient,
            databaseContainer: database,
            connectionRepository: connectionRepository,
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
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            _ = repository.tokenWaiters
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
            connectionRepository: connectionRepository,
            tokenExpirationRetryStrategy: retryStrategy,
            timerType: DefaultTimer.self
        )

        XCTAssertEqual(repository.currentUserId, databaseUserId)
    }

    func test_setToken_tokenIsUpdated() {
        XCTAssertNil(repository.currentToken)

        let newToken = Token.unique()

        repository.setToken(token: newToken, completeTokenWaiters: false)

        XCTAssertEqual(repository.currentToken, newToken)
    }

    func test_updatingToken_updatesUserId() throws {
        let databaseUserId = "the-id"
        try database.createCurrentUser(id: databaseUserId)

        // Recreate repository to trigger init
        repository = AuthenticationRepository(
            apiClient: apiClient,
            databaseContainer: database,
            connectionRepository: connectionRepository,
            tokenExpirationRetryStrategy: retryStrategy,
            timerType: DefaultTimer.self
        )

        XCTAssertEqual(repository.currentUserId, databaseUserId)

        // Update token

        let newUserId = "new-user-id"
        let token = Token.unique(userId: newUserId)
        repository.setToken(token: token, completeTokenWaiters: false)

        XCTAssertEqual(repository.currentUserId, newUserId)
    }

    func test_setToken_tokenIsUpdated_callsTokenWaiters_whenRequired() {
        let expectation = self.expectation(description: "Calls token waiter")
        repository.provideToken { _ in
            expectation.fulfill()
        }

        XCTAssertNil(repository.currentToken)

        let newToken = Token.unique()

        repository.setToken(token: newToken, completeTokenWaiters: true)

        XCTAssertEqual(repository.currentToken, newToken)
        waitForExpectations(timeout: 0.1)
    }

    func test_setToken_tokenIsUpdated_doesNotCallTokenWaiters_whenNotRequired() {
        repository.provideToken { _ in
            XCTFail()
        }

        XCTAssertNil(repository.currentToken)

        let newToken = Token.unique()

        repository.setToken(token: newToken, completeTokenWaiters: false)
        XCTAssertEqual(repository.currentToken, newToken)
    }

    // MARK: Connect user

    func test_connectUser_isNotGettingToken_tokenProviderFailure() throws {
        let userInfo = UserInfo(id: "123")

        // Token Provider Failure
        let testError = TestError()
        let provider: TokenProvider = { $0(.failure(testError)) }

        let completionExpectation = expectation(description: "Connect completion")
        var receivedError: Error?
        XCTAssertNil(repository.tokenProvider)

        repository.connectUser(userInfo: userInfo, tokenProvider: provider, completion: { error in
            receivedError = error
            completionExpectation.fulfill()
        })

        XCTAssertNotNil(repository.tokenProvider)
        waitForExpectations(timeout: 0.1)
        XCTAssertNil(repository.currentToken)
        XCTAssertEqual(receivedError, testError)
        XCTAssertNotCall(ConnectionRepository_Mock.Signature.connect, on: connectionRepository)
        XCTAssertNotCall(ConnectionRepository_Mock.Signature.forceConnectionInactiveMode, on: connectionRepository)
    }

    func test_connectUser_isNotGettingToken_tokenProviderSuccess_connectFailure() throws {
        let userInfo = UserInfo(id: "123")

        // Token Provider Success
        let providedToken = Token.unique()
        let provider: TokenProvider = { $0(.success(providedToken)) }

        // Simulate Failure on Connection Repository
        let testError = TestError()
        connectionRepository.connectResult = .failure(testError)

        let completionExpectation = expectation(description: "Connect completion")
        var receivedError: Error?
        XCTAssertNil(repository.tokenProvider)

        repository.connectUser(userInfo: userInfo, tokenProvider: provider, completion: { error in
            receivedError = error
            completionExpectation.fulfill()
        })

        XCTAssertNotNil(repository.tokenProvider)
        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(repository.currentToken, providedToken)
        XCTAssertCall(ConnectionRepository_Mock.Signature.connect, on: connectionRepository)
        XCTAssertCall(ConnectionRepository_Mock.Signature.forceConnectionInactiveMode, on: connectionRepository)
        XCTAssertEqual(receivedError, testError)
    }

    func test_connectUser_isNotGettingToken_tokenProviderSuccess_connectSuccess() throws {
        let userInfo = UserInfo(id: "123")

        // Token Provider Success
        let providedToken = Token.unique()
        let provider: TokenProvider = { $0(.success(providedToken)) }

        // Simulate Success on Connection Repository
        connectionRepository.connectResult = .success(())

        let completionExpectation = expectation(description: "Connect completion")
        var receivedError: Error?
        XCTAssertNil(repository.tokenProvider)

        repository.connectUser(userInfo: userInfo, tokenProvider: provider, completion: { error in
            receivedError = error
            completionExpectation.fulfill()
        })

        XCTAssertNotNil(repository.tokenProvider)
        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(repository.currentToken, providedToken)
        XCTAssertCall(ConnectionRepository_Mock.Signature.connect, on: connectionRepository)
        XCTAssertCall(ConnectionRepository_Mock.Signature.forceConnectionInactiveMode, on: connectionRepository)
        XCTAssertNil(receivedError)
    }

    func test_connectUser_multipleTimes_callsConnectionRepositoryOnlyOnce() throws {
        let userInfo = UserInfo(id: "123")

        // Token Provider Success, with delay to simulate real scenario
        let providedToken = Token.unique()
        let provider: TokenProvider = { completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion(.success(providedToken))
            }
        }

        // Simulate Success on Connection Repository
        connectionRepository.connectResult = .success(())

        XCTAssertNil(repository.tokenProvider)

        var expectations: [XCTestExpectation] = []
        (1...4).forEach { _ in
            let completionExpectation = self.expectation(description: "Connect completion")
            repository.connectUser(userInfo: userInfo, tokenProvider: provider, completion: { _ in
                completionExpectation.fulfill()
            })
            expectations.append(completionExpectation)
        }
        XCTAssertNotNil(repository.tokenProvider)
        XCTAssertEqual(expectations.count, 4)

        waitForExpectations(timeout: 0.2)

        XCTAssertEqual(repository.currentToken, providedToken)
        XCTAssertCall(ConnectionRepository_Mock.Signature.connect, on: connectionRepository, times: 1)
        XCTAssertCall(ConnectionRepository_Mock.Signature.forceConnectionInactiveMode, on: connectionRepository, times: 1)
    }

    func test_connectUser_updatesTokenProvider() throws {
        XCTAssertNil(repository.tokenProvider)

        let originalProviderCalled = self.expectation(description: "Initial token provider call")
        let originalTokenProvider: TokenProvider = { $0(.success(.unique())) }

        connectionRepository.connectResult = .success(())

        repository.connectUser(userInfo: nil, tokenProvider: originalTokenProvider, completion: { _ in
            originalProviderCalled.fulfill()
        })
        XCTAssertNotNil(repository.tokenProvider)

        wait(for: [originalProviderCalled], timeout: 0.1)

        let expectation = self.expectation(description: "Correct token provider call")
        let newTokenProvider: TokenProvider = { _ in
            expectation.fulfill()
        }
        repository.connectUser(userInfo: nil, tokenProvider: newTokenProvider, completion: { _ in })
        waitForExpectations(timeout: 0.1)
    }

    func test_connectUser_clearsTokenCompletionsQueueAfterSuccess() throws {
        XCTAssertNil(repository.tokenProvider)

        let delegate = AuthenticationRepositoryDelegateMock()
        repository.delegate = delegate

        connectionRepository.connectResult = .success(())
        connectionRepository.disconnectResult = .success(())

        // First user
        var initialCompletionCalls = 0

        let originalTokenProvider: TokenProvider = { $0(.success(.unique())) }
        let expectation1 = expectation(description: "Completion call 1")
        repository.connectUser(userInfo: nil, tokenProvider: originalTokenProvider, completion: { _ in
            initialCompletionCalls += 1
            expectation1.fulfill()
        })

        waitForExpectations(timeout: 0.1)

        XCTAssertEqual(initialCompletionCalls, 1)
        XCTAssertEqual(delegate.newStateCalls, 1)
        XCTAssertEqual(delegate.newState, .firstConnection)
        XCTAssertEqual(delegate.clearDataCalls, 0)

        // New token/user
        let newUserId = "user-id"
        var newTokenCompletionCalls = 0
        let expectation2 = expectation(description: "Completion call 2")
        let newTokenProvider: TokenProvider = { $0(.success(.unique(userId: newUserId))) }
        repository.connectUser(userInfo: nil, tokenProvider: newTokenProvider, completion: { _ in
            newTokenCompletionCalls += 1
            expectation2.fulfill()
        })

        waitForExpectations(timeout: 0.1)

        XCTAssertEqual(initialCompletionCalls, 1)
        XCTAssertEqual(newTokenCompletionCalls, 1)
        XCTAssertEqual(delegate.newStateCalls, 2)
        XCTAssertEqual(delegate.newState, .newUser)
        XCTAssertEqual(delegate.clearDataCalls, 1)

        // Refresh token
        var refreshTokenCompletionCalls = 0
        let expectation3 = expectation(description: "Completion call 2")
        let refreshTokenProvider: TokenProvider = { $0(.success(.unique(userId: newUserId))) }
        repository.connectUser(userInfo: nil, tokenProvider: refreshTokenProvider, completion: { _ in
            refreshTokenCompletionCalls += 1
            expectation3.fulfill()
        })

        waitForExpectations(timeout: 0.1)

        XCTAssertEqual(initialCompletionCalls, 1)
        XCTAssertEqual(newTokenCompletionCalls, 1)
        XCTAssertEqual(refreshTokenCompletionCalls, 1)
        XCTAssertEqual(delegate.newStateCalls, 3)
        XCTAssertEqual(delegate.newState, .newToken)
        XCTAssertEqual(delegate.clearDataCalls, 1)
    }

    // Prepare environment on a successful token retrieval

    private class AuthenticationRepositoryDelegateMock: AuthenticationRepositoryDelegate {
        var newState: EnvironmentState?
        var clearDataCalls: Int = 0
        var newStateCalls: Int = 0

        func didFinishSettingUpAuthenticationEnvironment(for state: EnvironmentState) {
            newStateCalls += 1
            newState = state
        }

        func clearCurrentUserData(completion: @escaping (Error?) -> Void) {
            clearDataCalls += 1
            completion(nil)
        }
    }

    func test_connectUser_prepareEnvironment_firstConnection() {
        let delegate = AuthenticationRepositoryDelegateMock()
        let userId = "user1"
        let newUserInfo = UserInfo(id: userId)
        let newToken = Token.unique(userId: userId)

        repository.delegate = delegate
        let error = testPrepareEnvironmentAfterConnect(existingToken: nil, newUserInfo: newUserInfo, newToken: newToken)

        XCTAssertNil(error)
        XCTAssertEqual(repository.currentUserId, userId)
        XCTAssertEqual(repository.currentToken, newToken)
        XCTAssertEqual(connectionRepository.updateWebSocketEndpointToken, newToken)
        XCTAssertCall(ConnectionRepository_Mock.Signature.updateWebSocketEndpointTokenInfo, on: connectionRepository)
        XCTAssertEqual(delegate.newStateCalls, 1)
        XCTAssertEqual(delegate.clearDataCalls, 0)
        XCTAssertEqual(delegate.newState, .firstConnection)
    }

    func test_connectUser_prepareEnvironment_sameUser() {
        let delegate = AuthenticationRepositoryDelegateMock()
        let existingUserId = "user2"
        let existingUserInfo = UserInfo(id: existingUserId)
        let existingToken = Token.unique(userId: existingUserId)

        repository.setToken(token: existingToken, completeTokenWaiters: false)

        XCTAssertEqual(repository.currentToken, existingToken)
        XCTAssertEqual(repository.currentUserId, existingUserId)

        let newToken = Token.unique(userId: existingUserId)

        repository.delegate = delegate
        let error = testPrepareEnvironmentAfterConnect(existingToken: nil, newUserInfo: existingUserInfo, newToken: newToken)

        XCTAssertNil(error)
        XCTAssertEqual(repository.currentUserId, existingUserId)
        XCTAssertEqual(repository.currentToken, newToken)
        XCTAssertEqual(connectionRepository.updateWebSocketEndpointToken, newToken)
        XCTAssertCall(ConnectionRepository_Mock.Signature.updateWebSocketEndpointTokenInfo, on: connectionRepository)
        XCTAssertEqual(delegate.newStateCalls, 1)
        XCTAssertEqual(delegate.clearDataCalls, 0)
        XCTAssertEqual(delegate.newState, .newToken)
    }

    func test_connectUser_prepareEnvironment_sameUser_sameToken() {
        let delegate = AuthenticationRepositoryDelegateMock()
        let existingUserId = "user2"
        let existingUserInfo = UserInfo(id: existingUserId)
        let existingToken = Token.unique(userId: existingUserId)

        repository.setToken(token: existingToken, completeTokenWaiters: false)

        XCTAssertEqual(repository.currentToken, existingToken)
        XCTAssertEqual(repository.currentUserId, existingUserId)

        let newToken = existingToken

        repository.delegate = delegate
        let error = testPrepareEnvironmentAfterConnect(existingToken: nil, newUserInfo: existingUserInfo, newToken: newToken)

        XCTAssertNil(error)
        XCTAssertEqual(existingToken, newToken)
        XCTAssertEqual(repository.currentUserId, existingUserId)
        XCTAssertEqual(repository.currentToken, newToken)
        XCTAssertEqual(connectionRepository.updateWebSocketEndpointToken, newToken)
        XCTAssertCall(ConnectionRepository_Mock.Signature.updateWebSocketEndpointTokenInfo, on: connectionRepository)
        XCTAssertEqual(delegate.newStateCalls, 1)
        XCTAssertEqual(delegate.clearDataCalls, 0)
        XCTAssertEqual(delegate.newState, .newToken)
    }

    func test_connectUser_prepareEnvironment_newUser_activeMode() {
        let delegate = AuthenticationRepositoryDelegateMock()
        let existingUserId = "userOld1"
        let existingToken = Token.unique(userId: existingUserId)
        var config = ChatClientConfig(apiKeyString: "")
        config.isClientInActiveMode = true
        connectionRepository = ConnectionRepository_Mock(client: ChatClient(config: config))
        repository = AuthenticationRepository(
            apiClient: apiClient,
            databaseContainer: database,
            connectionRepository: connectionRepository,
            tokenExpirationRetryStrategy: retryStrategy,
            timerType: DefaultTimer.self
        )

        repository.setToken(token: existingToken, completeTokenWaiters: false)

        XCTAssertEqual(repository.currentToken, existingToken)
        XCTAssertEqual(repository.currentUserId, existingUserId)

        let newUserId = "user8"
        let newUserInfo = UserInfo(id: newUserId)
        let newToken = Token.unique(userId: newUserId)

        connectionRepository.disconnectResult = .success(())
        repository.delegate = delegate
        let error = testPrepareEnvironmentAfterConnect(existingToken: nil, newUserInfo: newUserInfo, newToken: newToken)

        XCTAssertNil(error)
        XCTAssertEqual(repository.currentUserId, newUserId)
        XCTAssertEqual(repository.currentToken, newToken)
        XCTAssertEqual(connectionRepository.updateWebSocketEndpointToken, newToken)
        XCTAssertCall(ConnectionRepository_Mock.Signature.updateWebSocketEndpointTokenInfo, on: connectionRepository)
        XCTAssertEqual(delegate.newStateCalls, 1)
        XCTAssertEqual(delegate.clearDataCalls, 1)
        XCTAssertEqual(delegate.newState, .newUser)
    }

    func test_connectUser_prepareEnvironment_newUser_notActiveMode() {
        let delegate = AuthenticationRepositoryDelegateMock()
        let existingUserId = "userOld2"
        let existingToken = Token.unique(userId: existingUserId)
        var config = ChatClientConfig(apiKeyString: "")
        config.isClientInActiveMode = false
        connectionRepository = ConnectionRepository_Mock(client: ChatClient(config: config))
        repository = AuthenticationRepository(
            apiClient: apiClient,
            databaseContainer: database,
            connectionRepository: connectionRepository,
            tokenExpirationRetryStrategy: retryStrategy,
            timerType: DefaultTimer.self
        )

        repository.setToken(token: existingToken, completeTokenWaiters: false)

        XCTAssertEqual(repository.currentToken, existingToken)
        XCTAssertEqual(repository.currentUserId, existingUserId)

        let newUserId = "user9"
        let newUserInfo = UserInfo(id: newUserId)
        let newToken = Token.unique(userId: newUserId)

        repository.delegate = delegate
        let error = testPrepareEnvironmentAfterConnect(existingToken: nil, newUserInfo: newUserInfo, newToken: newToken)

        XCTAssertTrue(error is ClientError.ClientIsNotInActiveMode)
        XCTAssertEqual(repository.currentUserId, newUserId)
        XCTAssertEqual(repository.currentToken, newToken)
        XCTAssertNotCall(ConnectionRepository_Mock.Signature.updateWebSocketEndpointTokenInfo, on: connectionRepository)
        XCTAssertEqual(delegate.newStateCalls, 1)
        XCTAssertEqual(delegate.clearDataCalls, 0)
        XCTAssertEqual(delegate.newState, .newUser)
    }

    // MARK: Connect guest user

    func test_connectGuestUser_isNotGettingToken_tokenProviderFailure() throws {
        let userInfo = UserInfo(id: "123")

        // Token Provider Failure
        let apiError = TestError()

        let completionExpectation = expectation(description: "Connect completion")
        var receivedError: Error?
        XCTAssertNil(repository.tokenProvider)

        repository.connectGuestUser(userInfo: userInfo, completion: { error in
            receivedError = error
            completionExpectation.fulfill()
        })

        let requestCompletion = try XCTUnwrap(apiClient.request_completion as? ((Result<GuestUserTokenPayload, Error>) -> Void))
        requestCompletion(.failure(apiError))

        XCTAssertNotNil(repository.tokenProvider)
        waitForExpectations(timeout: 0.1)
        XCTAssertNil(repository.currentToken)
        XCTAssertEqual(receivedError, apiError)
        let request = try XCTUnwrap(apiClient.request_endpoint)
        XCTAssertEqual(request.path, .guest)
        XCTAssertNotCall(ConnectionRepository_Mock.Signature.connect, on: connectionRepository)
        XCTAssertNotCall(ConnectionRepository_Mock.Signature.forceConnectionInactiveMode, on: connectionRepository)
    }

    func test_connectGuestUser_isNotGettingToken_tokenProviderSuccess_connectFailure() throws {
        let userInfo = UserInfo(id: "123")

        // Token Provider Success
        let apiToken = Token.unique()

        // Simulate Failure on Connection Repository
        let testError = TestError()
        connectionRepository.connectResult = .failure(testError)

        let completionExpectation = expectation(description: "Connect completion")
        var receivedError: Error?
        XCTAssertNil(repository.tokenProvider)

        repository.connectGuestUser(userInfo: userInfo, completion: { error in
            receivedError = error
            completionExpectation.fulfill()
        })

        let requestCompletion = try XCTUnwrap(apiClient.request_completion as? ((Result<GuestUserTokenPayload, Error>) -> Void))
        requestCompletion(.success(GuestUserTokenPayload(user: CurrentUserPayload.dummy(userId: "", role: .user), token: apiToken)))

        XCTAssertNotNil(repository.tokenProvider)
        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(repository.currentToken, apiToken)
        let request = try XCTUnwrap(apiClient.request_endpoint)
        XCTAssertEqual(request.path, .guest)
        XCTAssertCall(ConnectionRepository_Mock.Signature.connect, on: connectionRepository)
        XCTAssertCall(ConnectionRepository_Mock.Signature.forceConnectionInactiveMode, on: connectionRepository)
        XCTAssertEqual(receivedError, testError)
    }

    func test_connectGuestUser_isNotGettingToken_tokenProviderSuccess_connectSuccess() throws {
        let userInfo = UserInfo(id: "123")

        // Token Provider Success
        let apiToken = Token.unique()

        // Simulate Success on Connection Repository
        connectionRepository.connectResult = .success(())

        let completionExpectation = expectation(description: "Connect completion")
        var receivedError: Error?
        XCTAssertNil(repository.tokenProvider)

        repository.connectGuestUser(userInfo: userInfo, completion: { error in
            receivedError = error
            completionExpectation.fulfill()
        })

        let requestCompletion = try XCTUnwrap(apiClient.request_completion as? ((Result<GuestUserTokenPayload, Error>) -> Void))
        requestCompletion(.success(GuestUserTokenPayload(user: CurrentUserPayload.dummy(userId: "", role: .user), token: apiToken)))

        XCTAssertNotNil(repository.tokenProvider)
        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(repository.currentToken, apiToken)
        let request = try XCTUnwrap(apiClient.request_endpoint)
        XCTAssertEqual(request.path, .guest)
        XCTAssertCall(ConnectionRepository_Mock.Signature.connect, on: connectionRepository)
        XCTAssertCall(ConnectionRepository_Mock.Signature.forceConnectionInactiveMode, on: connectionRepository)
        XCTAssertNil(receivedError)
    }

    // MARK: Clear Token Provider

    func test_clearTokenProvider_removesIt() {
        let userInfo = UserInfo(id: "123")
        repository.connectGuestUser(userInfo: userInfo, completion: { _ in })
        repository.setToken(token: .unique(), completeTokenWaiters: false)
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
        repository.setToken(token: .unique(), completeTokenWaiters: false)
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

        XCTAssertCall(RetryStrategy_Spy.Signature.nextRetryDelay, on: retryStrategy)
        XCTAssertCall(RetryStrategy_Spy.Signature.resetConsecutiveFailures, on: retryStrategy)
        XCTAssertNil(receivedError)
    }

    func test_refreshToken_failure() throws {
        let mockedError = ClientError("Mocked error")
        try setTokenProvider(mockedResult: .failure(mockedError))

        let receivedError = try refreshTokenAndWaitForResponse(mockedError: mockedError)

        XCTAssertCall(RetryStrategy_Spy.Signature.nextRetryDelay, on: retryStrategy)
        XCTAssertNotCall(RetryStrategy_Spy.Signature.resetConsecutiveFailures, on: retryStrategy)
        XCTAssertEqual(receivedError, mockedError)
    }

    func test_refreshToken_multipleCalls_theoreticApproach() throws {
        // Adding delay otherwise all the execution is 100% sync and we cannot simulate the scenario
        try setTokenProvider(mockedResult: .success(.unique()), delay: .milliseconds(10))
        retryStrategy.mock_nextRetryDelay.returns(0.01)

        connectionRepository.connectResult = .success(())

        (1...3).forEach { _ in
            let expectation = self.expectation(description: "Refresh token")
            repository.refreshToken { _ in
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 0.1)

        XCTAssertCall(RetryStrategy_Spy.Signature.nextRetryDelay, on: retryStrategy, times: 3)
        XCTAssertCall(RetryStrategy_Spy.Signature.resetConsecutiveFailures, on: retryStrategy, times: 1)
    }

    func test_refreshToken_multipleCalls_forcingRealisticDispatch() throws {
        // Adding delay otherwise all the execution is 100% sync and we cannot simulate the scenario
        try setTokenProvider(mockedResult: .success(.unique()), delay: .milliseconds(10))
        retryStrategy.mock_nextRetryDelay.returns(0)

        connectionRepository.connectResult = .success(())

        let expectation1 = expectation(description: "Initial Refresh token")
        repository.refreshToken { _ in
            expectation1.fulfill()
        }

        retryStrategy.mock_nextRetryDelay.returns(0.01)

        let expectation2 = expectation(description: "Refresh token 2")
        let expectation3 = expectation(description: "Refresh token 3")

        DispatchQueue.main.async {
            [expectation2, expectation3].forEach { expectation in
                self.repository.refreshToken { _ in
                    expectation.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 0.1)

        XCTAssertCall(RetryStrategy_Spy.Signature.nextRetryDelay, on: retryStrategy, times: 1)
        XCTAssertCall(RetryStrategy_Spy.Signature.resetConsecutiveFailures, on: retryStrategy, times: 1)
    }

    // MARK: Provide Token

    func test_provideToken_returnsValue_whenAlreadyHasToken() {
        let existingToken = Token.unique()
        repository.setToken(token: existingToken, completeTokenWaiters: false)

        var result: Result<Token, Error>?
        let expectation = self.expectation(description: "Provide Connection Id Completion")
        repository.provideToken(timeout: 0.1) {
            result = $0
            expectation.fulfill()
        }

        // Sync execution
        XCTAssertNotNil(result)

        waitForExpectations(timeout: 0.1)

        XCTAssertEqual(result?.value, existingToken)
    }

    func test_provideToken_returnsErrorOnTimeout() {
        var result: Result<Token, Error>?
        let expectation = self.expectation(description: "Provide Token Completion")
        repository.provideToken(timeout: 0.01) {
            result = $0
            expectation.fulfill()
        }
        XCTAssertNil(result)

        waitForExpectations(timeout: 0.1)

        XCTAssertTrue(result?.error is ClientError.WaiterTimeout)
    }

    func test_provideToken_returnsErrorOnMissingValue() {
        var result: Result<Token, Error>?
        let expectation = self.expectation(description: "Provide Token Completion")
        repository.provideToken(timeout: 0.1) {
            result = $0
            expectation.fulfill()
        }
        XCTAssertNil(result)

        // Complete with nil
        repository.completeTokenWaiters(token: nil)
        waitForExpectations(timeout: 0.1)

        XCTAssertTrue(result?.error is ClientError.MissingToken)
    }

    func test_provideToken_returnsValue_whenCompletingTokenWaiters() {
        var result: Result<Token, Error>?
        let expectation = self.expectation(description: "Provide Token Completion")
        repository.provideToken(timeout: 0.1) {
            result = $0
            expectation.fulfill()
        }
        XCTAssertNil(result)

        // Complete with token
        let token = Token.unique()
        repository.completeTokenWaiters(token: token)
        waitForExpectations(timeout: 0.1)

        XCTAssertEqual(result?.value, token)
    }

    // MARK: Helpers

    private func testPrepareEnvironmentAfterConnect(
        existingToken: Token?,
        newUserInfo: UserInfo,
        newToken: Token
    ) -> Error? {
        XCTAssertNil(repository.tokenProvider)

        // Simulate Success on Connection Repository
        connectionRepository.connectResult = .success(())

        // Token Provider Success
        let provider: TokenProvider = { $0(.success(newToken)) }

        let completionExpectation = expectation(description: "Connect completion")
        var receivedError: Error?
        repository.connectUser(userInfo: newUserInfo, tokenProvider: provider, completion: { error in
            receivedError = error
            completionExpectation.fulfill()
        })

        XCTAssertNotNil(repository.tokenProvider)
        waitForExpectations(timeout: 0.1)

        if connectionRepository.isClientInActiveMode {
            XCTAssertCall(ConnectionRepository_Mock.Signature.connect, on: connectionRepository)
            XCTAssertCall(ConnectionRepository_Mock.Signature.forceConnectionInactiveMode, on: connectionRepository)
        } else {
            XCTAssertNotCall(ConnectionRepository_Mock.Signature.connect, on: connectionRepository)
            XCTAssertNotCall(ConnectionRepository_Mock.Signature.forceConnectionInactiveMode, on: connectionRepository)
        }
        return receivedError
    }

    private func refreshTokenAndWaitForResponse(mockedError: Error?) throws -> Error? {
        XCTAssertNotNil(repository.tokenProvider)
        retryStrategy.mock_nextRetryDelay.returns(0.1)

        connectionRepository.connectResult = mockedError.map { .failure($0) } ?? .success(())

        let expectation = self.expectation(description: "Refresh token")
        var receivedError: Error?
        repository.refreshToken { error in
            receivedError = error
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
        return receivedError
    }

    private func setTokenProvider(mockedResult: Result<Token, Error>, delay: DispatchTimeInterval? = nil) throws {
        let tokenProvider: TokenProvider = { completion in
            if let delay = delay {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    completion(mockedResult)
                }
            } else {
                completion(mockedResult)
            }
        }
        connectionRepository.connectResult = .success(())
        var isFirstTime = true
        let expectation = self.expectation(description: "connect completes")
        repository.connectUser(userInfo: nil, tokenProvider: tokenProvider, completion: { _ in
            if isFirstTime {
                expectation.fulfill()
            }
            isFirstTime = false
        })

        waitForExpectations(timeout: 0.1)
        connectionRepository.cleanUp()
    }
}
