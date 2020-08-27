//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class TypingEventObserver_Tests: XCTestCase {
    var eventNotificationCenter: NotificationCenter!
    var observer: TypingEventObserver!
    
    // MARK: - Setup

    override func setUp() {
        super.setUp()

        eventNotificationCenter = NotificationCenter()
    }

    override func tearDown() {
        eventNotificationCenter = nil
        observer = nil
        
        super.tearDown()
    }
    
    func test_onlyTypingEventsAreObserved_whenNoFilterIsSpecified() {
        let typingEvent = TypingEvent.unique
        let otherEvent = OtherEvent()
        
        var receivedEvents: [TypingEvent] = []
        observer = TypingEventObserver(
            notificationCenter: eventNotificationCenter,
            callback: { receivedEvents.append($0) }
        )
        
        // Post a typing event and verify it's received
        eventNotificationCenter.post(.init(newEventReceived: typingEvent, sender: self))
        AssertAsync.willBeEqual(receivedEvents, [typingEvent])
        
        // Post a non-typing event and verify it's not received
        eventNotificationCenter.post(.init(newEventReceived: otherEvent, sender: self))
        AssertAsync.staysEqual(receivedEvents, [typingEvent])
    }
    
    func test_cidFilterIsAppliedToTypingEvents_whenSpecified() {
        let channelId: ChannelId = .unique
        let matchingTypingEvent = TypingEvent(isTyping: true, cid: channelId, userId: .unique)
        let otherTypingEvent = TypingEvent.unique
        
        var receivedEvents: [TypingEvent] = []
        observer = TypingEventObserver(
            notificationCenter: eventNotificationCenter,
            cid: channelId,
            callback: { receivedEvents.append($0) }
        )
        
        // Post a typing event matching the filter and verify it's received
        eventNotificationCenter.post(.init(newEventReceived: matchingTypingEvent, sender: self))
        AssertAsync.willBeEqual(receivedEvents, [matchingTypingEvent])
        
        // Post a non-matching event and verify it's not received
        eventNotificationCenter.post(.init(newEventReceived: otherTypingEvent, sender: self))
        AssertAsync.staysEqual(receivedEvents, [matchingTypingEvent])
    }
}

extension TypingEvent: Equatable {
    static var unique: Self = .init(isTyping: true, cid: .unique, userId: .newUniqueId)
    
    public static func == (lhs: TypingEvent, rhs: TypingEvent) -> Bool {
        lhs.cid == rhs.cid && lhs.userId == rhs.userId
    }
}

private struct OtherEvent: Event {}
