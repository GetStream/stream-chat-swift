//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class ChannelListUpdater_Tests: XCTestCase {
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainer!
    
    var listUpdater: ChannelListUpdater!
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = DatabaseContainerMock()
        
        listUpdater = ChannelListUpdater(database: database, apiClient: apiClient)
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        
        AssertAsync {
            Assert.canBeReleased(&listUpdater)
            Assert.canBeReleased(&database)
        }
        
        super.tearDown()
    }
    
    // MARK: - Update
    
    func test_update_makesCorrectAPICall() {
        // Simulate `update` call
        let query = ChannelListQuery(filter: .in(.members, values: [.unique]))
        listUpdater.update(channelListQuery: query)
        
        let referenceEndpoint: Endpoint<ChannelListPayload> = .channels(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_update_successfulResponseData_areSavedToDB() {
        // Simulate `update` call
        let query = ChannelListQuery(filter: .in(.members, values: [.unique]))
        var completionCalled = false
        listUpdater.update(channelListQuery: query, completion: { result in
            XCTAssertNil(result.error)
            completionCalled = true
        })
        
        // Simulate API response with channel data
        let cid = ChannelId(type: .messaging, id: .unique)
        let payload = ChannelListPayload(channels: [dummyPayload(with: cid)])
        apiClient.test_simulateResponse(.success(payload))
        
        // Assert the data is stored in the DB
        var channel: ChatChannel? {
            database.viewContext.channel(cid: cid)?.asModel()
        }
        AssertAsync {
            Assert.willBeTrue(channel != nil)
            Assert.willBeTrue(completionCalled)
        }
    }
    
    func test_update_errorResponse_isPropagatedToCompletion() {
        // Simulate `update` call
        let query = ChannelListQuery(filter: .in(.members, values: [.unique]))
        var completionCalledError: Error?
        listUpdater.update(channelListQuery: query, completion: { completionCalledError = $0.error })
        
        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<ChannelListPayload, Error>.failure(error))
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    func test_update_doesNotRetainSelf() {
        // Simulate `update` call
        listUpdater.update(channelListQuery: .init(filter: .in(.members, values: [.unique])))
        
        // Assert updater can be deallocated without waiting for the API response.
        AssertAsync.canBeReleased(&listUpdater)
    }
    
    func test_update_marksChannelsAsHidden_whenFilterIncludesHidden() {
        // Simulate `update` call with `.equal(.hidden, to: true)` filter
        let query = ChannelListQuery(
            filter: .and(
                [
                    .in(.members, values: [.unique]),
                    .equal(.hidden, to: true)
                ]
            )
        )
        var completionCalled = false
        listUpdater.update(channelListQuery: query, completion: { result in
            XCTAssertNil(result.error)
            completionCalled = true
        })
        
        // Simulate API response with channel data
        let cid = ChannelId(type: .messaging, id: .unique)
        let payload = ChannelListPayload(channels: [dummyPayload(with: cid)])
        apiClient.test_simulateResponse(.success(payload))
        
        // Assert the data is stored in the DB
        var channel: ChatChannel? {
            database.viewContext.channel(cid: cid)?.asModel()
        }
        AssertAsync {
            Assert.willBeTrue(channel != nil)
            Assert.willBeTrue(channel?.hiddenAt != nil)
            Assert.willBeTrue(completionCalled)
        }
    }
    
    // MARK: - Mark all read
    
    func test_markAllRead_makesCorrectAPICall() {
        listUpdater.markAllRead()
        
        let referenceEndpoint = Endpoint<EmptyResponse>.markAllRead()
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_markAllRead_successfulResponse_isPropagatedToCompletion() {
        var completionCalled = false
        listUpdater.markAllRead { error in
            XCTAssertNil(error)
            completionCalled = true
        }
        
        XCTAssertFalse(completionCalled)
        
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
        
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_markAllRead_errorResponse_isPropagatedToCompletion() {
        var completionCalledError: Error?
        listUpdater.markAllRead { completionCalledError = $0 }
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))
        
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
}
