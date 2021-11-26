//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ConnectionRecoveryUpdater_Tests: XCTestCase {
    var updater: ConnectionRecoveryUpdater!
    var mockChatClient: ChatClientMock!
    var mockConnectionMonitor: InternetConnectionMonitorMock!
    var mockBackgroundTaskScheduler: MockBackgroundTaskScheduler!
    
    // MARK: - Set up/tear down
    
    override func setUp() {
        super.setUp()
        
        mockConnectionMonitor = InternetConnectionMonitorMock()
        mockBackgroundTaskScheduler = MockBackgroundTaskScheduler()
        mockChatClient = makeMockChatClient(staysConnectedInBackground: false)
        
        updater = ConnectionRecoveryUpdater(
            client: mockChatClient,
            environment: makeMockEnvironment()
        )
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&updater)
        AssertAsync.canBeReleased(&mockChatClient)
        AssertAsync.canBeReleased(&mockConnectionMonitor)
        AssertAsync.canBeReleased(&mockBackgroundTaskScheduler)
        
        super.tearDown()
    }
    
    // MARK: - Client not connected
    
    func test_whenClientWasNotConnectedAndInternetComesBack_reconnectionDoesNotHappen() {
        // Simulate connection going down
        mockConnectionMonitor.status = .unavailable
        
        // Assert disconnect is not called
        XCTAssertFalse(mockChatClient.mockClientUpdater.disconnect_called)
        
        // Simulate connection comming back
        mockConnectionMonitor.status = .available(.great)
        
        // Assert the reconnection does not happen
        XCTAssertFalse(mockChatClient.mockClientUpdater.connect_called)
    }
    
    func test_whenActiveInBackgroundClientWasNotConnectedAndAppGoesToForeground_reconnectionDoesNotHappen() {
        // Create mock chat client active in background
        mockChatClient = makeMockChatClient(staysConnectedInBackground: true)
        
        // Create connection recovery updater
        updater = ConnectionRecoveryUpdater(client: mockChatClient, environment: makeMockEnvironment())
        
        // Simulate app going to background
        mockBackgroundTaskScheduler.startListeningForAppStateUpdates_onBackground?()
        
        // Assert disconnect is not called
        XCTAssertFalse(mockChatClient.mockClientUpdater.disconnect_called)
        // Background task is not started
        XCTAssertFalse(mockBackgroundTaskScheduler.beginBackgroundTask_called)
        
        // Simulate app going to foreground
        mockBackgroundTaskScheduler.startListeningForAppStateUpdates_onForeground?()
        
        // Assert the reconnection does not happen
        XCTAssertFalse(mockChatClient.mockClientUpdater.connect_called)
    }
    
    func test_whenPassiveInBackgroundClientWasNotConnectedAndAppGoesToForeground_reconnectionDoesNotHappen() {
        // Simulate app going to background
        mockBackgroundTaskScheduler.startListeningForAppStateUpdates_onBackground?()
        
        // Assert disconnect is not called
        XCTAssertFalse(mockChatClient.mockClientUpdater.disconnect_called)
        // Background task is not started
        XCTAssertFalse(mockBackgroundTaskScheduler.beginBackgroundTask_called)
        
        // Simulate app going to foreground
        mockBackgroundTaskScheduler.startListeningForAppStateUpdates_onForeground?()
        
        // Assert the reconnection does not happen
        XCTAssertFalse(mockChatClient.mockClientUpdater.connect_called)
    }
    
    // MARK: - Client connected and disconnected by the user
    
    func test_whenClientWasManuallyDisconnectedAndInternetComesBack_reconnectionDoesNotHappen() {
        // Connect chat client
        mockChatClient.connectGuestUser(userInfo: .init(id: .unique))
        mockChatClient.mockWebSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Manually disconnect chat client
        mockChatClient.disconnect()
        mockChatClient.mockWebSocketClient.simulateConnectionStatus(.disconnected(source: .userInitiated))
        
        // Reset values
        mockChatClient.mockClientUpdater.disconnect_called = false
        
        // Simulate connection going down and comming back
        mockConnectionMonitor.status = .unavailable
        
        // Assert disconnect is not called for one more time
        XCTAssertFalse(mockChatClient.mockClientUpdater.disconnect_called)
        
        // Simulate connection comming back
        mockConnectionMonitor.status = .available(.great)
        
        // Assert the reconnection does not happen
        XCTAssertFalse(mockChatClient.mockClientUpdater.connect_called)
    }
    
    func test_whenActiveClientWasManuallyDisconnectedAndAppGoesToForeground_reconnectionDoesNotHappen() {
        // Create mock chat client active in background
        mockChatClient = makeMockChatClient(staysConnectedInBackground: true)
        
        // Create connection recovery updater
        updater = ConnectionRecoveryUpdater(client: mockChatClient, environment: makeMockEnvironment())
        
        // Connect a chat client
        mockChatClient.connectGuestUser(userInfo: .init(id: .unique))
        mockChatClient.mockWebSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Manually disconnect chat client
        mockChatClient.disconnect()
        mockChatClient.mockWebSocketClient.simulateConnectionStatus(.disconnected(source: .userInitiated))
        
        // Reset values
        mockChatClient.mockClientUpdater.disconnect_called = false
        
        // Simulate app going to background
        mockBackgroundTaskScheduler.startListeningForAppStateUpdates_onBackground?()
        
        // Assert disconnect is not called for one more time
        XCTAssertFalse(mockChatClient.mockClientUpdater.disconnect_called)
        // Assert background task is not started
        XCTAssertFalse(mockBackgroundTaskScheduler.beginBackgroundTask_called)
        
        // Simulate app going to foreground
        mockBackgroundTaskScheduler.startListeningForAppStateUpdates_onForeground?()
        
        // Assert the reconnection does not happen
        XCTAssertFalse(mockChatClient.mockClientUpdater.connect_called)
    }
    
    func test_whenPassiveClientWasManuallyDisconnectedAndAppGoesToForeground_reconnectionDoesNotHappen() {
        // Connect a chat client
        mockChatClient.connectGuestUser(userInfo: .init(id: .unique))
        mockChatClient.mockWebSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Manually disconnect chat client
        mockChatClient.disconnect()
        mockChatClient.mockWebSocketClient.simulateConnectionStatus(.disconnected(source: .userInitiated))
        
        // Reset values
        mockChatClient.mockClientUpdater.disconnect_called = false
        
        // Simulate app going to background
        mockBackgroundTaskScheduler.startListeningForAppStateUpdates_onBackground?()
        
        // Assert disconnect is not called for one more time
        XCTAssertFalse(mockChatClient.mockClientUpdater.disconnect_called)
        // Assert background task is not started
        XCTAssertFalse(mockBackgroundTaskScheduler.beginBackgroundTask_called)
        
        // Simulate app going to foreground
        mockBackgroundTaskScheduler.startListeningForAppStateUpdates_onForeground?()
        
        // Assert the reconnection does not happen
        XCTAssertFalse(mockChatClient.mockClientUpdater.connect_called)
    }
    
    // MARK: - Client connected and disconnected by the system
    
    func test_whenClientWasConnectedAndInternetComesBack_reconnectionHappens() {
        // Connect a chat client
        mockChatClient.connectGuestUser(userInfo: .init(id: .unique))
        mockChatClient.mockWebSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Simulate connection going down
        mockConnectionMonitor.status = .unavailable
        
        // Assert disconnection is initiated by the system
        XCTAssertTrue(mockChatClient.mockClientUpdater.disconnect_called)
        XCTAssertEqual(mockChatClient.mockClientUpdater.disconnect_source, .systemInitiated)
        
        // Simulate client disconnection
        mockChatClient.mockWebSocketClient.simulateConnectionStatus(.disconnected(source: .systemInitiated))
        
        // Simulate connection comming back
        mockConnectionMonitor.status = .available(.great)
        
        // Assert the reconnection happens
        XCTAssertTrue(mockChatClient.mockClientUpdater.connect_called)
    }
    
    func test_whenPassiveInBackgroundClientWasConnectedAndAppGoesToForeground_reconnectionHappens() {
        // Connect chat client
        mockChatClient.connectGuestUser(userInfo: .init(id: .unique))
        mockChatClient.mockWebSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Simulate app going to background
        mockBackgroundTaskScheduler.startListeningForAppStateUpdates_onBackground?()
        
        // Assert disconnection is initiated by the system
        XCTAssertTrue(mockChatClient.mockClientUpdater.disconnect_called)
        XCTAssertEqual(mockChatClient.mockClientUpdater.disconnect_source, .systemInitiated)
        
        // Simulate client disconnection
        mockChatClient.mockWebSocketClient.simulateConnectionStatus(.disconnected(source: .systemInitiated))
        
        // Simulate app going to foreground
        mockBackgroundTaskScheduler.startListeningForAppStateUpdates_onForeground?()
        
        // Assert reconnection does happen
        XCTAssertTrue(mockChatClient.mockClientUpdater.connect_called)
    }
    
    func test_whenBackgroundTaskWasInterruptedAndAppGoesToForegroundWithInternetConnectionAvailable_reconnectionHappens() {
        // Create mock chat client active in background
        mockChatClient = makeMockChatClient(staysConnectedInBackground: true)
        
        // Create connection recovery updater
        updater = ConnectionRecoveryUpdater(client: mockChatClient, environment: makeMockEnvironment())
        
        // Connect a chat client
        mockChatClient.connectGuestUser(userInfo: .init(id: .unique))
        mockChatClient.mockWebSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Simulate app going to background
        mockBackgroundTaskScheduler.startListeningForAppStateUpdates_onBackground?()
        
        // Assert disconnect is not called because it should stay connected in background
        XCTAssertFalse(mockChatClient.mockClientUpdater.disconnect_called)
        // Assert background task is started so client stays connected in background
        XCTAssertTrue(mockBackgroundTaskScheduler.beginBackgroundTask_called)
        
        // Simulate backgroud task interruption
        mockBackgroundTaskScheduler.beginBackgroundTask_expirationHandler?()
        
        // Assert disconnect is initiated by the system
        XCTAssertTrue(mockChatClient.mockClientUpdater.disconnect_called)
        XCTAssertEqual(mockChatClient.mockClientUpdater.disconnect_source, .systemInitiated)
        
        // Simulate client disconnection
        mockChatClient.mockWebSocketClient.simulateConnectionStatus(.disconnected(source: .systemInitiated))
        
        // Simulate internet connection being available
        mockConnectionMonitor.status = .available(.great)
        
        // Simulate app going to foreground
        mockBackgroundTaskScheduler.startListeningForAppStateUpdates_onForeground?()
        
        // Assert the reconnection does happens
        XCTAssertTrue(mockChatClient.mockClientUpdater.connect_called)
    }
    
    func test_whenBackgroundTaskWasInterruptedAndAppGoesToForegroundWithInternetConnectionNotAvailable_reconnectionDoesNotHappens() {
        // Create mock chat client active in background
        mockChatClient = makeMockChatClient(staysConnectedInBackground: true)
        
        // Create connection recovery updater
        updater = ConnectionRecoveryUpdater(client: mockChatClient, environment: makeMockEnvironment())
        
        // Connect a chat client
        mockChatClient.connectGuestUser(userInfo: .init(id: .unique))
        mockChatClient.mockWebSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Simulate app going to background
        mockBackgroundTaskScheduler.startListeningForAppStateUpdates_onBackground?()
        
        // Assert disconnect is not called because it should stay connected in background
        XCTAssertFalse(mockChatClient.mockClientUpdater.disconnect_called)
        // Assert background task is started so client stays connected in background
        XCTAssertTrue(mockBackgroundTaskScheduler.beginBackgroundTask_called)
        
        // Simulate backgroud task interruption
        mockBackgroundTaskScheduler.beginBackgroundTask_expirationHandler?()
        
        // Assert disconnect is initiated by the system
        XCTAssertTrue(mockChatClient.mockClientUpdater.disconnect_called)
        XCTAssertEqual(mockChatClient.mockClientUpdater.disconnect_source, .systemInitiated)
        
        // Simulate client disconnection
        mockChatClient.mockWebSocketClient.simulateConnectionStatus(.disconnected(source: .systemInitiated))
        
        // Simulate internet connection being NOT available
        mockConnectionMonitor.status = .unavailable
        
        // Simulate app going to foreground
        mockBackgroundTaskScheduler.startListeningForAppStateUpdates_onForeground?()
        
        // Assert the reconnection does not happens
        XCTAssertFalse(mockChatClient.mockClientUpdater.connect_called)
    }
    
    func test_whenBackgroundTaskWasNotInterruptedAndAppGoesToForeground_reconnectionDoesNotHappen() {
        // Create mock chat client active in background
        mockChatClient = makeMockChatClient(staysConnectedInBackground: true)
        
        // Create connection recovery updater
        updater = ConnectionRecoveryUpdater(client: mockChatClient, environment: makeMockEnvironment())
        
        // Connect a chat client
        mockChatClient.connectGuestUser(userInfo: .init(id: .unique))
        mockChatClient.mockWebSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Simulate app going to background
        mockBackgroundTaskScheduler.startListeningForAppStateUpdates_onBackground?()
        
        // Assert disconnect is not called because it should stay connected in background
        XCTAssertFalse(mockChatClient.mockClientUpdater.disconnect_called)
        // Assert background task is started so client stays connected in background
        XCTAssertTrue(mockBackgroundTaskScheduler.beginBackgroundTask_called)
        
        // Simulate app going to foreground
        mockBackgroundTaskScheduler.startListeningForAppStateUpdates_onForeground?()
        
        // Assert background task is ended
        XCTAssertTrue(mockBackgroundTaskScheduler.endBackgroundTask_called)
        
        // Assert the reconnection does not happen since client was not disconnected
        XCTAssertFalse(mockChatClient.mockClientUpdater.connect_called)
    }
    
    // MARK: - Private
    
    private func makeMockChatClient(staysConnectedInBackground: Bool) -> ChatClientMock {
        var config = ChatClientConfig(apiKeyString: .unique)
        config.staysConnectedInBackground = staysConnectedInBackground
        return ChatClientMock(config: config)
    }
    
    private func makeMockEnvironment() -> ConnectionRecoveryUpdater.Environment {
        .init(
            internetConnectionBuilder: {
                InternetConnectionMock(
                    monitor: self.mockConnectionMonitor,
                    notificationCenter: $0
                )
            },
            backgroundTaskSchedulerBuilder: {
                self.mockBackgroundTaskScheduler
            }
        )
    }
}

extension ChannelListQuery: Equatable {
    public static func == (lhs: ChannelListQuery, rhs: ChannelListQuery) -> Bool {
        lhs.filter == rhs.filter &&
        lhs.messagesLimit == rhs.messagesLimit &&
        lhs.options == rhs.options &&
        lhs.pagination == rhs.pagination
    }
}
