//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class ChannelListQueryUpdater_Tests: StressTestCase {
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainer!
    
    var queryUpdater: ChannelListQueryUpdater<DefaultDataTypes>!
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = try! DatabaseContainer(kind: .inMemory)
        
        queryUpdater = ChannelListQueryUpdater(database: database, webSocketClient: webSocketClient, apiClient: apiClient)
    }
    
    func test_makesCorrectAPICall() {
        // Simulate `update` call
        let query = ChannelListQuery(filter: .in("member", ["Luke"]))
        queryUpdater.update(channelListQuery: query)
        
        let referenceEndpoint: Endpoint<ChannelListPayload<DefaultDataTypes>> = .channels(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_successfullReponseData_areSavedToDB() {
        // Simulate `update` call
        let query = ChannelListQuery(filter: .in("member", ["Luke"]))
        var completionCalled = false
        queryUpdater.update(channelListQuery: query, completion: { error in
            XCTAssertNil(error)
            completionCalled = true
        })
        
        // Simualte API response with channel data
        let cid = ChannelId(type: .messaging, id: .unique)
        let payload = ChannelListPayload<DefaultDataTypes>(channels: [dummyPayload(with: cid)])
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
    
    func test_errorReponse_isPropagatedToCompletion() {
        // Simulate `update` call
        let query = ChannelListQuery(filter: .in("member", ["Luke"]))
        var completionCalledError: Error?
        queryUpdater.update(channelListQuery: query, completion: { completionCalledError = $0 })
        
        // Simualte API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<ChannelListPayload<DefaultDataTypes>, Error>.failure(error))
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
}
