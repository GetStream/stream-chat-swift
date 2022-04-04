//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MemberEventObserver_Tests: XCTestCase {
    var eventNotificationCenter: NotificationCenter!
    var observer: MemberEventObserver!
    
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
    
    func test_onlyMemberEventsAreObserved_whenNoFilterIsSpecified() {
        let memberEvent = TestMemberEvent.unique
        let otherEvent = OtherEvent()
        
        var receivedEvents: [MemberEvent] = []
        observer = MemberEventObserver(
            notificationCenter: eventNotificationCenter,
            callback: { receivedEvents.append($0) }
        )
        
        // Post a member event and verify it's received
        eventNotificationCenter.post(.init(newEventReceived: memberEvent, sender: self))
        AssertAsync.willBeEqual(receivedEvents as? [TestMemberEvent], [memberEvent])
        
        // Post a non-member event and verify it's not received
        eventNotificationCenter.post(.init(newEventReceived: otherEvent, sender: self))
        AssertAsync.staysEqual(receivedEvents as? [TestMemberEvent], [memberEvent])
    }
    
    func test_cidFilterIsAppliedToMemberEvents_whenSpecified() {
        let channelId: ChannelId = .unique
        let matchingMemberEvent = TestMemberEvent(cid: channelId, memberUserId: .unique)
        let otherMemberEvent = TestMemberEvent.unique
        
        var receivedEvents: [MemberEvent] = []
        observer = MemberEventObserver(
            notificationCenter: eventNotificationCenter,
            cid: channelId,
            callback: { receivedEvents.append($0) }
        )
        
        // Post a member event matching the filter and verify it's received
        eventNotificationCenter.post(.init(newEventReceived: matchingMemberEvent, sender: self))
        AssertAsync.willBeEqual(receivedEvents as? [TestMemberEvent], [matchingMemberEvent])
        
        // Post a non-matching event and verify it's not received
        eventNotificationCenter.post(.init(newEventReceived: otherMemberEvent, sender: self))
        AssertAsync.staysEqual(receivedEvents as? [TestMemberEvent], [matchingMemberEvent])
    }
}
