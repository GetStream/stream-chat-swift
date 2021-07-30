//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class ChannelWatchStateUpdater_Tests: StressTestCase {
    typealias ExtraData = NoExtraData
    
    var database: DatabaseContainerMock!
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    
    var channelWatchStateUpdater: ChannelWatchStateUpdater<ExtraData>?
    
    override func setUp() {
        super.setUp()
        
        database = DatabaseContainerMock()
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        
        channelWatchStateUpdater = ChannelWatchStateUpdater(
            database: database,
            eventNotificationCenter: webSocketClient.eventNotificationCenter,
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
        AssertAsync.staysTrue(apiClient.request_endpoint == nil)
    }
    
    func test_apiClient_is_not_called_on_empty_channels() {
        // Simulate WebSocket successfully connected
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert APIClient is not called for empty channels
        AssertAsync.staysTrue(apiClient.request_endpoint == nil)
    }
    
    func test_apiClient_called_on_webSocket_connected() throws {
        let cid: ChannelId = .unique
        
        try database.createChannel(cid: cid, withMessages: false)
        
        XCTAssertNil(apiClient.request_endpoint)
        
        // Simulate WebSocket successfully connected
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        let query: ChannelListQuery = .init(
            filter: .in(.cid, values: [cid]),
            pageSize: 1
        )
        
        let endpoint: Endpoint<ChannelListPayload> = .channels(query: query)
        
        // Assert APIClient is called with the correct endpoint
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(endpoint))
    }
    
    func test_channelWatchStateUpdater_doesNotRetainItself() throws {
        // Create channel in the database
        try database.createChannel()
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert api-client is called
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)
        
        // Assert `channelWatchStateUpdater` can be released before network response comes
        AssertAsync.canBeReleased(&channelWatchStateUpdater)
    }
}
