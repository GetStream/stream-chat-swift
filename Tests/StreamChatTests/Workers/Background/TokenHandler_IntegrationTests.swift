//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class TokenHandler_IntegrationTests: XCTestCase {
    var time: VirtualTime!
    
    override func setUp() {
        super.setUp()
        
        time = VirtualTime()
        VirtualTimeTimer.time = time
    }
    
    override func tearDown() {
        VirtualTimeTimer.invalidate()
        time = nil
        
        super.tearDown()
    }
    
    func test_whenAPIRequestFailsWithExpiredTokenErrorWhenWebsocketIsConnected() {
        // GIVEN
        let client = createClient()
        
        let userId: UserId = .unique
        let token = Token.unique(userId: userId)
        let refreshedToken = Token.unique(userId: userId)
        
        var tokenProviderCompletion: TokenWaiter?
        let tokenProviderCalledOnce = expectation(description: "connection provider is called once")
        tokenProviderCalledOnce.assertForOverFulfill = false
        let tokenProviderCalledTwice = expectation(description: "connection provider is called twice")
        tokenProviderCalledTwice.expectedFulfillmentCount = 2
        
        let tokenProvider: TokenProvider = {
            tokenProviderCompletion = $0
            tokenProviderCalledOnce.fulfill()
            tokenProviderCalledTwice.fulfill()
        }
        
        // Connect chat client
        var connectUserCompletionError: Error?
        let connectUserCompletionCalled = expectation(description: "connectUser is called")
        client.connectUser(userInfo: .init(id: userId), tokenProvider: tokenProvider) { error in
            connectUserCompletionError = error
            connectUserCompletionCalled.fulfill()
        }
        
        time.run(numberOfSeconds: 0.1)
        wait(for: [tokenProviderCalledOnce], timeout: defaultTimeout)
        tokenProviderCompletion?(.success(token))
        
        wait(for: [client.mockWebSocketClient.connect_expectation], timeout: defaultTimeout)
        XCTAssertEqual(client.mockWebSocketClient.connect_calledCounter, 1)
        client.mockWebSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        wait(for: [connectUserCompletionCalled], timeout: defaultTimeout)
        XCTAssertNil(connectUserCompletionError)
        
        // WHEN
        var tokenRefresherCompletionError: Error?
        let tokenRefresherCompletionCalled = expectation(description: "tokenRefresher is called")
        let expiredTokenErrorPayload = ErrorPayload(code: 40, message: "Test", statusCode: 400)
        let expiredTokenError = ClientError.ExpiredToken(with: expiredTokenErrorPayload)

        client.mockAPIClient.init_tokenRefresher(expiredTokenError) { error in
            tokenRefresherCompletionError = error
            tokenRefresherCompletionCalled.fulfill()
        }
        
        // THEN
        wait(for: [client.mockWebSocketClient.disconnect_expectation], timeout: defaultTimeout)
        let disconnectionSource: WebSocketConnectionState.DisconnectionSource = .serverInitiated(error: expiredTokenError)
        XCTAssertEqual(client.mockWebSocketClient.disconnect_source, disconnectionSource)
        XCTAssertEqual(client.mockWebSocketClient.disconnect_calledCounter, 1)
        client.mockWebSocketClient.simulateConnectionStatus(.disconnected(source: disconnectionSource))
        client.mockWebSocketClient.disconnect_completion?()
        
        client.mockWebSocketClient.cleanUp()
        time.run(numberOfSeconds: 5)
        XCTAssertFalse(client.mockWebSocketClient.connect_called)
        
        time.run(numberOfSeconds: 1)
        wait(for: [tokenProviderCalledTwice], timeout: defaultTimeout)
        tokenProviderCompletion?(.success(refreshedToken))
        XCTAssertEqual(client.tokenHandler.currentToken, refreshedToken)
        
        wait(for: [client.mockWebSocketClient.connect_expectation], timeout: defaultTimeout)
        client.mockWebSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        wait(for: [tokenRefresherCompletionCalled], timeout: defaultTimeout)
        XCTAssertNil(tokenRefresherCompletionError)
    }
    
    // MARK: - Private
    
    private func createClient() -> ChatClient {
        var config = ChatClientConfig(apiKey: .init(.unique))
        config.isLocalStorageEnabled = false
        
        var environment: ChatClient.Environment = .mock
        environment.clientUpdaterBuilder = ChatClientUpdater.init
        environment.tokenHandlerBuilder = {
            DefaultTokenHandler {
                DefaultTokenRefreshFlow(
                    tokenProvider: $0,
                    maximumTokenRefreshAttempts: 10,
                    attemptTimeout: 10,
                    retryStrategy: DefaultRetryStrategy(),
                    timerType: VirtualTimeTimer.self
                )
            }
        }
        environment.connectionRecoveryHandlerBuilder = {
            DefaultConnectionRecoveryHandler(
                webSocketClient: $0,
                eventNotificationCenter: $1,
                syncRepository: $2,
                backgroundTaskScheduler: nil,
                internetConnection: $4,
                reconnectionStrategy: DefaultRetryStrategy(),
                reconnectionTimerType: VirtualTimeTimer.self,
                keepConnectionAliveInBackground: $5
            )
        }
        
        return ChatClient(
            config: config,
            environment: environment
        )
    }
}
