//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class TypingEventsSender_Tests: XCTestCase {
    var webSocketClient: WebSocketClient_Mock!
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!
    var time: VirtualTime!
    var eventSender: TypingEventsSender!
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClient_Mock()
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        
        time = VirtualTime()
        VirtualTimeTimer.time = time
        
        eventSender = TypingEventsSender(database: database, apiClient: apiClient)
        eventSender.timer = VirtualTimeTimer.self
    }
    
    override func tearDown() {
        VirtualTimeTimer.invalidate()
        time = nil
        eventSender = nil
        database = nil
        apiClient.cleanUp()
        apiClient = nil
        super.tearDown()
    }
    
    func test_keystroke_withoutParentMessageId_makesCorrectAPICalls() {
        // Send keystroke.
        let cid = ChannelId.unique
        let parentMessageId: MessageId? = nil
        eventSender.keystroke(in: cid, parentMessageId: parentMessageId)
        
        let startTypingEndpoint: Endpoint<EmptyResponse> = .startTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(startTypingEndpoint))
        apiClient.request_endpoint = nil
        
        // Wait for the start typing event timeout.
        time.run(numberOfSeconds: .startTypingEventTimeout)
        
        // Make sure the stop typing event has been sent.
        let stopTypingEndpoint: Endpoint<EmptyResponse> = .stopTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(stopTypingEndpoint))
    }
    
    func test_keystroke_sendsStartTypingAndStopTypingEvents() {
        // Send keystroke.
        let cid = ChannelId.unique
        let parentMessageId = MessageId.unique
        eventSender.keystroke(in: cid, parentMessageId: parentMessageId)
        
        let startTypingEndpoint: Endpoint<EmptyResponse> = .startTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(startTypingEndpoint))
        apiClient.request_endpoint = nil
        
        // Wait for the start typing event timeout.
        time.run(numberOfSeconds: .startTypingEventTimeout)
        
        // Make sure the stop typing event has been sent.
        let stopTypingEndpoint: Endpoint<EmptyResponse> = .stopTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(stopTypingEndpoint))
    }
    
    func test_keystroke_sendsStartTyping_andResetsTimer() {
        // Send keystroke.
        let cid = ChannelId.unique
        let parentMessageId = MessageId.unique
        eventSender.keystroke(in: cid, parentMessageId: parentMessageId)
        
        let startTypingEndpoint: Endpoint<EmptyResponse> = .startTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(startTypingEndpoint))
        
        // Before typing timeout send keystroke after `.startTypingEventTimeout` - 1 to avoid sending the stop typing event.
        time.run(numberOfSeconds: .startTypingEventTimeout - 1)
        eventSender.keystroke(in: cid, parentMessageId: parentMessageId)
        
        // Check the stop typing event wasn't sent after another `.startTypingEventTimeout` - 1.
        time.run(numberOfSeconds: .startTypingEventTimeout - 1)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 1)
    }
    
    func test_keystroke_sendsStartTypingEvent_afterResendInterval() {
        // Send keystroke.
        let cid = ChannelId.unique
        let parentMessageId = MessageId.unique
        eventSender.keystroke(in: cid, parentMessageId: parentMessageId)
        
        // Make a loop with a step less than `.startTypingEventTimeout` until `.startTypingResendInterval`.
        let stepTimeInterval = .startTypingEventTimeout - 1
        
        repeat {
            time.run(numberOfSeconds: stepTimeInterval)
            eventSender.keystroke(in: cid, parentMessageId: parentMessageId)
        } while time.currentTime < .startTypingResendInterval
        
        // Only 1 other startTyping event should be sent, for a total of 2 events
        let startTypingEndpoint: Endpoint<EmptyResponse> = .startTypingEvent(cid: cid, parentMessageId: parentMessageId)
        let calls: [AnyEndpoint] = apiClient.request_allRecordedCalls.map(\.endpoint)
        XCTAssertEqual(calls, [AnyEndpoint(startTypingEndpoint), AnyEndpoint(startTypingEndpoint)])
    }
    
    func test_stopTyping_withoutParentMessageId_makesCorrectAPICall() {
        let cid = ChannelId.unique
        let parentMessageId: MessageId? = nil
        
        // Call stopTyping
        eventSender.stopTyping(in: cid, parentMessageId: parentMessageId)
        
        // Check the start typing event has been sent.
        let startTypingEndpoint: Endpoint<EmptyResponse> = .stopTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(startTypingEndpoint))
    }
    
    func test_stopTyping_afterKeystroke() {
        // Send keystroke.
        let cid = ChannelId.unique
        let parentMessageId = MessageId.unique
        eventSender.keystroke(in: cid, parentMessageId: parentMessageId)
        
        // Check the start typing event has been sent.
        let startTypingEndpoint: Endpoint<EmptyResponse> = .startTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(startTypingEndpoint))
        
        time.run(numberOfSeconds: .startTypingEventTimeout - 1)
        
        // Force to stop typing and it should reset scheduled stop typing timer.
        eventSender.stopTyping(in: cid, parentMessageId: parentMessageId)
        let stopTypingEndpoint: Endpoint<EmptyResponse> = .stopTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(stopTypingEndpoint))
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 2)
        
        // Check the scheduled stop typing timer was cancelled.
        time.run(numberOfSeconds: .startTypingEventTimeout)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 2)
    }
    
    func test_stopTypingIsSent_afterKeystroke_whenDeallocated() {
        let cid = ChannelId.unique
        let parentMessageId = MessageId.unique
        
        // First send keystroke to store `cid` internally inside `typingEventsSender` to have CID for stopTyping.
        eventSender.keystroke(in: cid, parentMessageId: parentMessageId)
        
        // Check the start typing event has been sent.
        let startTypingEndpoint: Endpoint<EmptyResponse> = .startTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(startTypingEndpoint))
        
        // Deinit the eventSender
        eventSender = nil
        
        // Make sure the stop typing event has been sent.
        let stopTypingEndpoint: Endpoint<EmptyResponse> = .stopTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(stopTypingEndpoint))
    }
    
    func test_startTyping_withoutParentMessageId_makesCorrectAPICall() {
        let cid = ChannelId.unique
        let parentMessageId: MessageId? = nil
        
        // Call startTyping
        eventSender.startTyping(in: cid, parentMessageId: parentMessageId)
        
        // Check the start typing event has been sent.
        let startTypingEndpoint: Endpoint<EmptyResponse> = .startTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(startTypingEndpoint))
    }
    
    func test_startTyping_sendsStartTypingEvent() {
        let cid = ChannelId.unique
        let parentMessageId = MessageId.unique
        
        // Call startTyping
        eventSender.startTyping(in: cid, parentMessageId: parentMessageId)
        
        // Check the start typing event has been sent.
        let startTypingEndpoint: Endpoint<EmptyResponse> = .startTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(startTypingEndpoint))
    }
    
    func test_stopTyping_afterStartTyping() {
        let cid = ChannelId.unique
        let parentMessageId = MessageId.unique
        
        // Call startTyping
        eventSender.startTyping(in: cid, parentMessageId: parentMessageId)
        
        // Check the start typing event has been sent.
        let startTypingEndpoint: Endpoint<EmptyResponse> = .startTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(startTypingEndpoint))
        
        // Call stopTyping
        eventSender.stopTyping(in: cid, parentMessageId: parentMessageId)
        
        // Make sure the stop typing event has been sent.
        let stopTypingEndpoint: Endpoint<EmptyResponse> = .stopTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(stopTypingEndpoint))
    }
    
    func test_stopTypingIsSent_afterStartTyping_whenDeallocated() {
        let cid = ChannelId.unique
        let parentMessageId = MessageId.unique
        
        // First send startTyping to store `cid` internally inside `typingEventsSender` to have CID for stopTyping.
        eventSender.startTyping(in: cid, parentMessageId: parentMessageId)
        
        // Check the start typing event has been sent.
        let startTypingEndpoint: Endpoint<EmptyResponse> = .startTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(startTypingEndpoint))
        
        // Deinit the eventSender
        eventSender = nil
        
        // Make sure the stop typing event has been sent.
        let stopTypingEndpoint: Endpoint<EmptyResponse> = .stopTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(stopTypingEndpoint))
    }
    
    func test_stopTypingIsNotSentTwice_afterKeystroke_whenDeallocated() {
        let cid = ChannelId.unique
        let parentMessageId = MessageId.unique
        
        // First send startTyping to store `cid` internally inside `typingEventsSender` to have CID for stopTyping.
        eventSender.keystroke(in: cid, parentMessageId: parentMessageId)
        
        // Check the start typing event has been sent.
        let startTypingEndpoint: Endpoint<EmptyResponse> = .startTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(startTypingEndpoint))
        
        // Run the time until stopTyping is sent by the timer
        time.run(numberOfSeconds: .startTypingEventTimeout)
        
        // Make sure the stop typing event has been sent.
        let stopTypingEndpoint: Endpoint<EmptyResponse> = .stopTypingEvent(cid: cid, parentMessageId: parentMessageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(stopTypingEndpoint))
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 2)
        
        // Deinit the eventSender
        eventSender = nil
        
        // Make sure no other call has been made
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 2)
    }
}
