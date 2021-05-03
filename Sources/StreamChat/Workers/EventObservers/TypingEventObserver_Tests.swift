//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
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
        let matchingTypingEvent = TypingEvent.startTyping(cid: channelId)
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
    static var unique: Self = try!
        .init(from: EventPayload<NoExtraData>(eventType: .userStartTyping, cid: .unique, user: .dummy(userId: .unique)))
    
    static func startTyping(cid: ChannelId = .unique, userId: UserId = .unique) -> TypingEvent {
        try! .init(from: EventPayload<NoExtraData>(eventType: .userStartTyping, cid: cid, user: .dummy(userId: userId)))
    }
    
    static func stopTyping(cid: ChannelId = .unique, userId: UserId = .unique) -> TypingEvent {
        try! .init(from: EventPayload<NoExtraData>(eventType: .userStopTyping, cid: cid, user: .dummy(userId: userId)))
    }
    
    public static func == (lhs: TypingEvent, rhs: TypingEvent) -> Bool {
        lhs.isTyping == rhs.isTyping && lhs.cid == rhs.cid && lhs.userId == rhs.userId
    }
}

extension CleanUpTypingEvent: Equatable {
    public static func == (lhs: CleanUpTypingEvent, rhs: CleanUpTypingEvent) -> Bool {
        lhs.cid == rhs.cid && lhs.userId == rhs.userId
    }
}

private struct OtherEvent: Event {}
