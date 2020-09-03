//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class EventSender_Tests: StressTestCase {
    typealias ExtraData = DefaultDataTypes
    
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainerMock!
    var time: VirtualTime!
    var eventSender: EventSender<ExtraData>!
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = try! DatabaseContainerMock(kind: .inMemory)
        
        time = VirtualTime()
        VirtualTimeTimer.time = time
        
        eventSender = EventSender(database: database, webSocketClient: webSocketClient, apiClient: apiClient)
        eventSender.timer = VirtualTimeTimer.self
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        super.tearDown()
    }
    
    func test_keystroke_startTypingAndStopAfterTimeout() throws {
        // Send keystroke.
        let cid = ChannelId.unique
        eventSender.keystroke(in: cid)
        
        var referenceEndpoint: Endpoint<EventPayload<ExtraData>> = .event(cid: cid, eventType: .userStartTyping)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
        apiClient.request_endpoint = nil
        
        // Wait timeout.
        time.run(numberOfSeconds: .startTypingEventTimeout)
        
        // Check stop typing did send.
        referenceEndpoint = .event(cid: cid, eventType: .userStopTyping)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_keystroke_startTypingAndResetStopTyping() throws {
        // Send keystroke.
        let cid = ChannelId.unique
        eventSender.keystroke(in: cid)
        
        let referenceEndpoint: Endpoint<EventPayload<ExtraData>> = .event(cid: cid, eventType: .userStartTyping)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
        apiClient.request_endpoint = nil
        
        // Before typing timeout send keystroke after 4 sec (timeout 5 sec).
        time.run(numberOfSeconds: .startTypingEventTimeout - 1)
        eventSender.keystroke(in: cid)
        
        // Check stop event didn't send.
        XCTAssertNil(apiClient.request_endpoint)
        
        // Check stop event didn't send after another 4 sec.
        time.run(numberOfSeconds: .startTypingEventTimeout - 1)
        XCTAssertNil(apiClient.request_endpoint)
    }
    
    func test_keystroke_StartTypingForLongTime() {
        // Send keystroke.
        let cid = ChannelId.unique
        eventSender.keystroke(in: cid)
        apiClient.request_endpoint = nil
        
        var requests = [AnyEndpoint?]()
        
        // Make a loop with a step of 3 sec until 20 sec (`.startTypingResendInterval`) + 1 step
        // to be sure the new request was sent. The last time should be 21 sec at the end of loop.
        for _ in 0..<(Int(TimeInterval.startTypingResendInterval / (.startTypingEventTimeout - 2)) + 1) {
            XCTAssertNil(apiClient.request_endpoint)
            time.run(numberOfSeconds: .startTypingEventTimeout - 2)
            eventSender.keystroke(in: cid)
            requests.append(apiClient.request_endpoint)
        }
        
        let referenceEndpoint: Endpoint<EventPayload<ExtraData>> = .event(cid: cid, eventType: .userStartTyping)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_stopTyping() throws {
        // Send keystroke.
        let cid = ChannelId.unique
        eventSender.keystroke(in: cid)
        
        var referenceEndpoint: Endpoint<EventPayload<ExtraData>> = .event(cid: cid, eventType: .userStartTyping)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
        
        time.run(numberOfSeconds: .startTypingEventTimeout - 1)
        
        eventSender.stopTyping(in: cid)
        referenceEndpoint = .event(cid: cid, eventType: .userStopTyping)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
        apiClient.request_endpoint = nil
        
        time.run(numberOfSeconds: .startTypingEventTimeout)
        XCTAssertNil(apiClient.request_endpoint)
    }
}
