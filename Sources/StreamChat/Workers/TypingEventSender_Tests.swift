//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class TypingEventsSender_Tests: XCTestCase {
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainerMock!
    var time: VirtualTime!
    var eventSender: TypingEventsSender!
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = DatabaseContainerMock()
        
        time = VirtualTime()
        VirtualTimeTimer.time = time
        
        eventSender = TypingEventsSender(database: database, apiClient: apiClient)
        eventSender.timer = VirtualTimeTimer.self
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        AssertAsync.canBeReleased(&database)
        super.tearDown()
    }
    
    func test_keystroke_startTypingAndStopAfterTimeout() throws {
        // Send keystroke.
        let cid = ChannelId.unique
        eventSender.keystroke(in: cid)
        
        let startTypingEndpoint: Endpoint<EmptyResponse> = .sendEvent(cid: cid, eventType: .userStartTyping)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(startTypingEndpoint))
        apiClient.request_endpoint = nil
        
        // Wait for the start typing event timeout.
        time.run(numberOfSeconds: .startTypingEventTimeout)
        
        // Make sure the stop typing event has been sent.
        let stopTypingEndpoint: Endpoint<EmptyResponse> = .sendEvent(cid: cid, eventType: .userStopTyping)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(stopTypingEndpoint))
    }
    
    func test_keystroke_startTypingAndResetStopTyping() throws {
        // Send keystroke.
        let cid = ChannelId.unique
        eventSender.keystroke(in: cid)
        
        let startTypingEndpoint: Endpoint<EmptyResponse> = .sendEvent(cid: cid, eventType: .userStartTyping)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(startTypingEndpoint))
        
        // Before typing timeout send keystroke after `.startTypingEventTimeout` - 1 to avoid sending the stop typing event.
        time.run(numberOfSeconds: .startTypingEventTimeout - 1)
        eventSender.keystroke(in: cid)
        
        // Check the stop typing event wasn't sent after another `.startTypingEventTimeout` - 1.
        time.run(numberOfSeconds: .startTypingEventTimeout - 1)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 1)
    }
    
    func test_keystroke_StartTypingForLongTime() {
        // Send keystroke.
        let cid = ChannelId.unique
        eventSender.keystroke(in: cid)
        
        var requests = [AnyEndpoint?]()
        
        // Make a loop with a step less then `.startTypingEventTimeout` until `.startTypingResendInterval`.
        let stepTimeInterval = .startTypingEventTimeout - 1
        
        repeat {
            time.run(numberOfSeconds: stepTimeInterval)
            eventSender.keystroke(in: cid)
            requests.append(apiClient.request_endpoint)
        } while time.currentTime < .startTypingResendInterval
        
        // Another start typing event should be sent.
        let startTypingEndpoint: Endpoint<EmptyResponse> = .sendEvent(cid: cid, eventType: .userStartTyping)
        let calls: [AnyEndpoint] = apiClient.request_allRecordedCalls.map(\.endpoint)
        XCTAssertEqual(calls, [AnyEndpoint(startTypingEndpoint), AnyEndpoint(startTypingEndpoint)])
    }
    
    func test_stopTyping() throws {
        // Send keystroke.
        let cid = ChannelId.unique
        eventSender.keystroke(in: cid)
        
        // Check the start typing event has been sent.
        let startTypingEndpoint: Endpoint<EmptyResponse> = .sendEvent(cid: cid, eventType: .userStartTyping)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(startTypingEndpoint))
        
        time.run(numberOfSeconds: .startTypingEventTimeout - 1)
        
        // Force to stop typing and it should reset scheduled stop typing timer.
        eventSender.stopTyping(in: cid)
        let stopTypingEndpoint: Endpoint<EmptyResponse> = .sendEvent(cid: cid, eventType: .userStopTyping)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(stopTypingEndpoint))
        
        // Check the scheduled stop typing timer was cancelled.
        time.run(numberOfSeconds: .startTypingEventTimeout)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 2)
    }
    
    func test_typingEventsSender_sendsStopTyping_whenDealocated() {
        let cid = ChannelId.unique
        
        // First send keystroke to store `cid` internally inside `typingEventsSender` to have CID for stopTyping.
        eventSender.keystroke(in: cid)
        
        // Check the start typing event has been sent.
        let startTypingEndpoint: Endpoint<EmptyResponse> = .sendEvent(cid: cid, eventType: .userStartTyping)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(startTypingEndpoint))
        
        // Deinit the eventSender
        eventSender = nil
        
        // Make sure the stop typing event has been sent.
        let stopTypingEndpoint: Endpoint<EmptyResponse> = .sendEvent(cid: cid, eventType: .userStopTyping)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(stopTypingEndpoint))
    }
}
