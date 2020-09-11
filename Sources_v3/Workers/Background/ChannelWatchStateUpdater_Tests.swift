//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class ChannelWatchStateUpdater_Tests: StressTestCase {
    typealias ExtraData = DefaultDataTypes
    
    var database: DatabaseContainerMock!
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    
    var channelWatchStateUpdater: ChannelWatchStateUpdater<ExtraData>?
    
    override func setUp() {
        super.setUp()
        
        database = try! DatabaseContainerMock(kind: .inMemory)
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        
        channelWatchStateUpdater = ChannelWatchStateUpdater(
            database: database,
            webSocketClient: webSocketClient,
            apiClient: apiClient
        )
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        
        AssertAsync {
            Assert.canBeReleased(&channelWatchStateUpdater)
            Assert.canBeReleased(&database)
            Assert.canBeReleased(&webSocketClient)
            Assert.canBeReleased(&apiClient)
        }
        
        super.tearDown()
    }
    
    func test_WebSocketConnectedProcessor_ignores_other_events() throws {
        let cid1: ChannelId = .unique
        let cid2: ChannelId = .unique
        
        try database.createChannel(cid: cid1, withMessages: false)
        try database.createChannel(cid: cid2, withMessages: false)
        
        webSocketClient.simulateConnectionStatus(.connecting)
        webSocketClient.simulateConnectionStatus(.disconnected(error: .none))
        webSocketClient.simulateConnectionStatus(.waitingForConnectionId)
        
        // Assert APIClient is not called for other events
        XCTAssertNil(apiClient.request_endpoint)
    }
    
    func test_apiClient_is_not_called_on_empty_channels() {
        // Simulate WebSocket successfully connected
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert APIClient is not called for empty channels
        XCTAssertNil(apiClient.request_endpoint)
    }
    
    func test_apiClient_called_on_websocket_connected() throws {
        let cid: ChannelId = .unique
        
        try database.createChannel(cid: cid, withMessages: false)
        
        XCTAssertNil(apiClient.request_endpoint)
        
        // Simulate WebSocket successfully connected
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        let query: ChannelListQuery = .init(
            filter: .in("cid", [cid].map(\.rawValue)),
            pagination: [.limit(1)],
            options: [.watch]
        )
        
        let endpoint: Endpoint<ChannelListPayload<ExtraData>> = .channels(query: query)
        
        // Assert APIClient is called with the correct endpoint
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(endpoint))
    }
}
