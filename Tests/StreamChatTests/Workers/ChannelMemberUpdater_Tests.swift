//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelMemberUpdater_Tests: XCTestCase {
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainerMock!
    
    var updater: ChannelMemberUpdater!
    
    // MARK: Setup
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = DatabaseContainerMock()
        
        updater = .init(database: database, apiClient: apiClient)
    }
    
    override func tearDown() {
        webSocketClient = nil
        apiClient.cleanUp()
        apiClient = nil
        database = nil
        updater = nil
        
        super.tearDown()
    }
    
    // MARK: - Ban user

    func test_banMember_makesCorrectAPICall() {
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        let timeoutInMinutes = 15
        let reason: String = .unique

        // Simulate `banMember` call
        updater.banMember(userId, in: cid, for: timeoutInMinutes, reason: reason)

        // Assert correct endpoint is called
        XCTAssertEqual(
            apiClient.request_endpoint,
            AnyEndpoint(.banMember(userId, cid: cid, timeoutInMinutes: timeoutInMinutes, reason: reason))
        )
    }

    func test_banMember_propagatesSuccessfulResponse() {
        // Simulate `banMember` call
        var completionCalled = false
        updater.banMember(.unique, in: .unique) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_banMember_propagatesError() {
        // Simulate `banMember` call
        var completionCalledError: Error?
        updater.banMember(.unique, in: .unique) { error in
            completionCalledError = error
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    // MARK: - Unban user

    func test_unbanMember_makesCorrectAPICall() {
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        
        // Simulate `unbanMember` call
        updater.unbanMember(userId, in: cid)

        // Assert correct endpoint is called
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(.unbanMember(userId, cid: cid)))
    }

    func test_unbanMember_propagatesSuccessfulResponse() {
        // Simulate `unbanMember` call
        var completionCalled = false
        updater.unbanMember(.unique, in: .unique) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_unbanMember_propagatesError() {
        // Simulate `unbanMember` call
        var completionCalledError: Error?
        updater.unbanMember(.unique, in: .unique) { error in
            completionCalledError = error
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
}
