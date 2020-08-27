//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class HealthCheckMiddleware_Tests: XCTestCase {
    var middleware: HealthCheckMiddleware!
    var webSocketClient: WebSocketClientMock!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClientMock()
        middleware = HealthCheckMiddleware(webSocketClient: webSocketClient)
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&webSocketClient)
        
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_middleware_forwardsNonHealthCheckEvents() throws {
        let event = TestEvent()
        
        // Simulate incoming public event
        let forwardedEvent = try await {
            middleware.handle(event: event, completion: $0)
        }
        
        // Assert event is forwared as it is
        XCTAssertEqual(forwardedEvent as? TestEvent, event)
    }
    
    func test_middleware_filtersHealthCheckEvents_ifClientIsDeallocated() throws {
        let event = HealthCheckEvent(connectionId: .unique)
        
        // Deallocate the client
        AssertAsync.canBeReleased(&webSocketClient)
        
        // Simulate `HealthCheckEvent`
        var forwardedEvent: Event?
        middleware.handle(event: event) {
            forwardedEvent = $0
        }
        
        // Assert event is not forwared
        AssertAsync.staysTrue(forwardedEvent == nil)
    }
    
    func test_middleware_handlesHealthCheckEvents() throws {
        let event = HealthCheckEvent(connectionId: .unique)
        
        // Simulate `HealthCheckEvent`
        var forwardedEvent: Event?
        middleware.handle(event: event) {
            forwardedEvent = $0
        }
        
        AssertAsync {
            // Assert event is not forwared
            Assert.staysTrue(forwardedEvent == nil)
            // Connection state is updated
            Assert.willBeEqual(self.middleware.webSocketClient?.connectionState, .connected(connectionId: event.connectionId))
        }
    }
}

// MARK: - Helpers

private struct TestEvent: Event, Equatable {
    let uuid: UUID = .init()
}
