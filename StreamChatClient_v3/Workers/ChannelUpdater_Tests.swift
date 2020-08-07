//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class ChannelUpdater_Tests: StressTestCase {
    typealias ExtraData = DefaultDataTypes
    
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainer!
    
    var queryUpdater: ChannelUpdater<ExtraData>!
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = try! DatabaseContainer(kind: .inMemory)
        
        queryUpdater = ChannelUpdater(database: database, webSocketClient: webSocketClient, apiClient: apiClient)
    }
    
    func test_updateChannelQuery_makesCorrectAPICall() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery<ExtraData>(channelId: .unique)
        queryUpdater.update(channelQuery: query)
        
        let referenceEndpoint: Endpoint<ChannelPayload<ExtraData>> = .channel(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_updateChannelQuery_successfulResponseData_areSavedToDB() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery<ExtraData>(channelId: .unique)
        var completionCalled = false
        queryUpdater.update(channelQuery: query, completion: { error in
            XCTAssertNil(error)
            completionCalled = true
        })
        
        // Simulate API response with channel data
        let cid = ChannelId(type: .messaging, id: .unique)
        let payload = dummyPayload(with: cid)
        apiClient.test_simulateResponse(.success(payload))
        
        // Assert the data is stored in the DB
        var channel: Channel? {
            database.viewContext.loadChannel(cid: cid)
        }
        AssertAsync {
            Assert.willBeTrue(channel != nil)
            Assert.willBeTrue(completionCalled)
        }
    }
    
    func test_updateChannelQuery_errorResponse_isPropagatedToCompletion() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery<ExtraData>(channelId: .unique)
        var completionCalledError: Error?
        queryUpdater.update(channelQuery: query, completion: { completionCalledError = $0 })
        
        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<ChannelPayload<ExtraData>, Error>.failure(error))
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Mute channel

    func test_muteChannel_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let mute = true

        // Simulate `muteChannel(cid:, mute:, completion:)` call
        queryUpdater.muteChannel(cid: channelID, mute: mute)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .muteChannel(cid: channelID, mute: mute)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_muteChannel_successfulResponse_isPropagatedToCompletion() {
        // Simulate `muteChannel(cid:, mute:, completion:)` call
        var completionCalled = false
        queryUpdater.muteChannel(cid: .unique, mute: true) { error in
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

    func test_muteChannel_errorResponse_isPropagatedToCompletion() {
        // Simulate `muteChannel(cid:, mute:, completion:)` call
        var completionCalledError: Error?
        queryUpdater.muteChannel(cid: .unique, mute: true) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Delete channel

    func test_deleteChannel_makesCorrectAPICall() {
        let channelID = ChannelId.unique

        // Simulate `deleteChannel(cid:, completion:)` call
        queryUpdater.deleteChannel(cid: channelID)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .deleteChannel(cid: channelID)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_deleteChannel_successfulResponse_isPropagatedToCompletion() {
        // Simulate `deleteChannel(cid:, completion:)` call
        var completionCalled = false
        queryUpdater.deleteChannel(cid: .unique) { error in
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

    func test_deleteChannel_errorResponse_isPropagatedToCompletion() {
        // Simulate `deleteChannel(cid:, completion:)` call
        var completionCalledError: Error?
        queryUpdater.deleteChannel(cid: .unique) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Hide channel

    func test_hideChannel_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let userID = UserId.unique
        let clearHistory = true

        // Simulate `hideChannel(cid:, userId:, clearHistory:, completion:)` call
        queryUpdater.hideChannel(cid: channelID, userId: userID, clearHistory: clearHistory)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .hideChannel(cid: channelID, userId: userID, clearHistory: clearHistory)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_hideChannel_successfulResponse_isPropagatedToCompletion() {
        // Simulate `hideChannel(cid:, userId:, clearHistory:, completion:)` call
        var completionCalled = false
        queryUpdater.hideChannel(cid: .unique, userId: .unique, clearHistory: true) { error in
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

    func test_hideChannel_errorResponse_isPropagatedToCompletion() {
        // Simulate `hideChannel(cid:, userId:, clearHistory:, completion:)` call
        var completionCalledError: Error?
        queryUpdater.hideChannel(cid: .unique, userId: .unique, clearHistory: true) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Show channel

    func test_showChannel_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let userID = UserId.unique

        // Simulate `showChannel(cid:, userId:)` call
        queryUpdater.showChannel(cid: channelID, userId: userID)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .showChannel(cid: channelID, userId: userID)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_showChannel_successfulResponse_isPropagatedToCompletion() {
        // Simulate `showChannel(cid:, userId:)` call
        var completionCalled = false
        queryUpdater.showChannel(cid: .unique, userId: .unique) { error in
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

    func test_showChannel_errorResponse_isPropagatedToCompletion() {
        // Simulate `showChannel(cid:, userId:)` call
        var completionCalledError: Error?
        queryUpdater.showChannel(cid: .unique, userId: .unique) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
}
