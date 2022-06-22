//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelEventsController_Tests: XCTestCase {
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!
    var notificationCenter: EventNotificationCenter_Mock!
    var eventSender: EventSender_Mock!
    var callbackQueueID: UUID!
    var callbackQueue: DispatchQueue!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        notificationCenter = EventNotificationCenter_Mock(database: database)
        eventSender = EventSender_Mock(database: database, apiClient: apiClient)
        callbackQueueID = UUID()
        callbackQueue = .testQueue(withId: callbackQueueID)
    }
    
    override func tearDown() {
        callbackQueueID = nil
        
        apiClient.cleanUp()
        eventSender.cleanUp()
        AssertAsync {
            Assert.canBeReleased(&apiClient)
            Assert.canBeReleased(&notificationCenter)
            Assert.canBeReleased(&database)
            Assert.canBeReleased(&eventSender)
            Assert.canBeReleased(&callbackQueue)
        }
        
        super.tearDown()
    }
    
    // MARK: - Channel events controller creation
    
    func test_client_buildsEventControllerCorrectly() {
        // Create channel identifier.
        let cid: ChannelId = .unique
        
        // Create channel events controller via chat client.
        let channelEventsController = ChatClient.mock().channelEventsController(for: cid)
        
        // Assert `cid` is propagated to events controller.
        XCTAssertEqual(channelEventsController.cid, cid)
    }
    
    func test_channelController_buildsEventControllerCorrectly() {
        // Create channel identifier.
        let cid: ChannelId = .unique
        
        // Create channel controller for the given cid.
        let channelController = ChannelControllerSpy(channelQuery: .init(cid: cid))
        
        // Create channel events controller via channel controller.
        let channelEventsController = channelController.eventsController()
        
        // Assert `cid` from channel controller is propagated to events controller.
        XCTAssertEqual(channelEventsController.cid, cid)
    }
    
    // MARK: - Channel identifier
    
    func test_cid_isTakenFromCidProvider() {
        // Create channel identifier.
        var cid: ChannelId?
        
        // Create controller.
        let controller = ChannelEventsController(
            cidProvider: { cid },
            eventSender: eventSender,
            notificationCenter: notificationCenter
        )
        
        // Assert controller returns valid cid.
        XCTAssertEqual(controller.cid, cid)
        
        // Simulate cid change.
        cid = .unique
        
        // Assert controller returns valid cid.
        XCTAssertEqual(controller.cid, cid)
    }
    
    // MARK: - Send event
    
    func test_sendEvent_whenThereIsNoChannelId_throwsError() throws {
        // Create events controller and assign a test callback queue.
        let controller = ChannelEventsController(
            cidProvider: { nil },
            eventSender: eventSender,
            notificationCenter: notificationCenter
        )
        controller.callbackQueue = callbackQueue
        
        // Simulate `sendEvent` and wait for completion.
        let error: Error? = try waitFor { [callbackQueueID] completion in
            controller.sendEvent(IdeaEventPayload.unique) { error in
                AssertTestQueue(withId: callbackQueueID!)
                completion(error)
            }
        }
        
        // Assert `ClientError.ChannelNotCreatedYet` is received.
        XCTAssertTrue(error is ClientError.ChannelNotCreatedYet)
    }
    
    func test_sendEvent_callsEventSender() throws {
        let cid: ChannelId = .unique
        let payload: IdeaEventPayload = .unique
                
        // Create an events controller with `cidProvider` returning nil.
        let controller = ChannelEventsController(
            cidProvider: { cid },
            eventSender: eventSender,
            notificationCenter: notificationCenter
        )
        
        // Simulate `sendEvent`.
        controller.sendEvent(payload)
        
        // Assert cid and payload are propagated to.
        XCTAssertEqual(eventSender.sendEvent_cid, controller.cid)
        XCTAssertEqual(eventSender.sendEvent_payload as? IdeaEventPayload, payload)
    }
    
    func test_sendEvent_propagatesError() throws {
        let cid: ChannelId = .unique
        let payload: IdeaEventPayload = .unique
                
        // Create events controller and assign a test callback queue.
        let controller = ChannelEventsController(
            cidProvider: { cid },
            eventSender: eventSender,
            notificationCenter: notificationCenter
        )
        controller.callbackQueue = callbackQueue
        
        // Simulate `sendEvent`.
        var completionError: Error?
        controller.sendEvent(payload) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID!)
            completionError = $0
        }
        
        // Simulate API response with the error.
        let networkError = TestError()
        eventSender.sendEvent_completion?(networkError)
        
        // Assert error is propogated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }
    
    func test_sendEvent_propagatesNilError() throws {
        // Create events controller and assign a test callback queue.
        let controller = ChannelEventsController(
            cidProvider: { .unique },
            eventSender: eventSender,
            notificationCenter: notificationCenter
        )
        controller.callbackQueue = callbackQueue
        
        // Simulate `sendEvent` and catch the completion.
        var completionCalled = false
        controller.sendEvent(IdeaEventPayload.unique) { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID!)
            XCTAssertNil(error)
            completionCalled = true
        }
        
        // Simulate sucessful API response.
        eventSender.sendEvent_completion?(nil)
        
        // Assert nil error is propogated.
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_sendEvent_keepsControllerAlive() throws {
        // Create events controller.
        var controller: ChannelEventsController? = ChannelEventsController(
            cidProvider: { .unique },
            eventSender: eventSender,
            notificationCenter: notificationCenter
        )
        
        // Simulate `sendEvent` and catch the completion.
        controller?.sendEvent(IdeaEventPayload.unique)
        
        // Keep only weak ref to controller.
        weak var weakController = controller
        controller = nil
        
        // Assert controller is kept alive.
        AssertAsync.willBeTrue(weakController != nil)
        
        // Restore strong reference to controller
        controller = weakController!
        
        // Simulate API response.
        eventSender.sendEvent_completion?(nil)
        eventSender.sendEvent_completion = nil
        
        // Assert controller can be released.
        AssertAsync.canBeReleased(&controller)
    }
    
    // MARK: - Event propagation
    
    func test_onlyEventsRelatedToChannel_areForwardedToDelegate() throws {
        let cid: ChannelId = .unique
        
        // Create events controller and assign a test callback queue.
        let controller = ChannelEventsController(
            cidProvider: { cid },
            eventSender: eventSender,
            notificationCenter: notificationCenter
        )
        let delegate = EventsController_Delegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        controller.callbackQueue = callbackQueue
        
        // Simulate incoming events.
        let eventPayload = EventPayload(eventType: .channelUpdated, channel: .dummy(cid: cid), createdAt: .unique)
        try database.writeSynchronously {
            try $0.saveChannel(payload: eventPayload.channel!, query: nil, cache: nil)
        }
        let currentChannelEvent = try ChannelUpdatedEventDTO(from: eventPayload)
            .toDomainEvent(session: database.viewContext) as! ChannelUpdatedEvent
        
        let currentChannelCustomEvent = UnknownChannelEvent(
            type: .init(rawValue: .unique),
            cid: cid,
            userId: .unique,
            createdAt: .unique,
            payload: [:]
        )
        let anotherChannelEvent = TestMemberEvent(cid: .unique, memberUserId: .unique)
        
        let events: [Event] = [
            currentChannelEvent,
            anotherChannelEvent,
            currentChannelCustomEvent
        ]
        
        for event in events {
            let notification = Notification(newEventReceived: event, sender: self)
            notificationCenter.post(notification)
        }
        
        // Assert only events for current channel are received
        AssertAsync {
            Assert.willBeEqual(delegate.events.count, 2)
            Assert.willBeTrue(delegate.events.first is ChannelUpdatedEvent)
            Assert.willBeTrue(delegate.events.last is UnknownChannelEvent)
        }
    }
}
