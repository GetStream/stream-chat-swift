//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class ChannelQueryUpdater_Tests: StressTestCase {
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
    
    func test_makesCorrectAPICall() {
        // Simulate `update` call
        let query = ChannelQuery<ExtraData>(channelId: .unique)
        queryUpdater.update(channelQuery: query)
        
        let referenceEndpoint: Endpoint<ChannelPayload<ExtraData>> = .channel(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_successfullReponseData_areSavedToDB() {
        // Simulate `update` call
        let query = ChannelQuery<ExtraData>(channelId: .unique)
        var completionCalled = false
        queryUpdater.update(channelQuery: query, completion: { error in
            XCTAssertNil(error)
            completionCalled = true
        })
        
        // Simualte API response with channel data
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
    
    func test_errorReponse_isPropagatedToCompletion() {
        // Simulate `update` call
        let query = ChannelQuery<ExtraData>(channelId: .unique)
        var completionCalledError: Error?
        queryUpdater.update(channelQuery: query, completion: { completionCalledError = $0 })
        
        // Simualte API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<ChannelPayload<ExtraData>, Error>.failure(error))
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
}
