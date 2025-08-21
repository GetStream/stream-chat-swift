//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class LivestreamChannelController_Combine_Tests: iOS13TestCase {
    var livestreamChannelController: LivestreamChannelController!
    var client: ChatClient_Mock!
    var channelQuery: ChannelQuery!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        
        client = ChatClient.mock(config: ChatClient_Mock.defaultMockedConfig)
        channelQuery = ChannelQuery(cid: .unique)
        livestreamChannelController = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client
        )
        cancellables = []
    }

    override func tearDown() {
        // Release existing subscriptions and make sure the controller gets released, too
        cancellables = nil
        AssertAsync.canBeReleased(&livestreamChannelController)
        livestreamChannelController = nil
        client?.cleanUp()
        client = nil
        channelQuery = nil
        super.tearDown()
    }

    // MARK: - Channel Change Publisher

    func test_channelChangePublisher() {
        // setup Initial Channel
        let mockUpdater = ChannelUpdater_Mock(
            channelRepository: client.channelRepository,
            messageRepository: client.messageRepository,
            paginationStateHandler: client.makeMessagesPaginationStateHandler(),
            database: client.databaseContainer,
            apiClient: client.apiClient
        )

        // Create controller with mock updater
        livestreamChannelController = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client,
            updater: mockUpdater
        )

        // Load initial channel data
        let exp = expectation(description: "sync completes")
        livestreamChannelController.synchronize { _ in
            exp.fulfill()
        }
        let channelPayload = ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!))
        mockUpdater.update_completion?(.success(channelPayload))
        waitForExpectations(timeout: defaultTimeout)

        // Setup Recording publishers
        var recording = Record<ChatChannel?, Never>.Recording()

        // Setup the chain without additional receive(on:) to avoid double async dispatch
        livestreamChannelController
            .channelChangePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)

        // Don't keep weak reference - use the controller directly for easier debugging
        let newChannel: ChatChannel = .mock(cid: channelQuery.cid!, name: .unique, imageURL: .unique(), extraData: [:])
        let event = ChannelUpdatedEvent(
            channel: newChannel,
            user: .mock(id: .unique),
            message: nil,
            createdAt: .unique
        )
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: LivestreamChannelController? = livestreamChannelController
        livestreamChannelController = nil

        // Simulate channel update event
        controller?.eventsController(
            EventsController(notificationCenter: client.eventNotificationCenter),
            didReceiveEvent: event
        )

        // Use AssertAsync to wait for the async update (delegate callback happens on main queue)
        AssertAsync {
            Assert.willBeEqual(recording.output.count, 3)
            Assert.willBeEqual(recording.output.last??.name, newChannel.name)
        }
    }

    func test_channelChangePublisher_keepsControllerAlive() {
        // Setup the chain
        livestreamChannelController
            .channelChangePublisher
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: LivestreamChannelController? = livestreamChannelController
        livestreamChannelController = nil

        // Assert controller is kept alive by the publisher.
        AssertAsync.staysTrue(controller != nil)
    }

    // MARK: - Messages Changes Publisher

    func test_messagesChangesPublisher() {
        // Setup Recording publishers
        var recording = Record<[ChatMessage], Never>.Recording()

        // Setup the chain
        livestreamChannelController
            .messagesChangesPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: LivestreamChannelController? = livestreamChannelController
        livestreamChannelController = nil

        let newMessage1: ChatMessage = .mock(id: .unique, cid: channelQuery.cid!, text: "Message 1", author: .mock(id: .unique))
        let newMessage2: ChatMessage = .mock(id: .unique, cid: channelQuery.cid!, text: "Message 2", author: .mock(id: .unique))
        
        // Simulate new message events
        let event1 = MessageNewEvent(
            user: .mock(id: .unique),
            message: newMessage1,
            channel: .mock(cid: channelQuery.cid!),
            createdAt: .unique,
            watcherCount: nil,
            unreadCount: nil
        )
        
        let event2 = MessageNewEvent(
            user: .mock(id: .unique),
            message: newMessage2,
            channel: .mock(cid: channelQuery.cid!),
            createdAt: .unique,
            watcherCount: nil,
            unreadCount: nil
        )
        
        // Send the events
        controller?.eventsController(
            EventsController(notificationCenter: client.eventNotificationCenter),
            didReceiveEvent: event1
        )
        
        controller?.eventsController(
            EventsController(notificationCenter: client.eventNotificationCenter),
            didReceiveEvent: event2
        )

        // Use AssertAsync to wait for the async updates
        AssertAsync {
            Assert.willBeEqual(recording.output.count, 3)
        }
    }

    func test_messagesChangesPublisher_keepsControllerAlive() {
        // Setup the chain
        livestreamChannelController
            .messagesChangesPublisher
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: LivestreamChannelController? = livestreamChannelController
        livestreamChannelController = nil

        // Assert controller is kept alive by the publisher.
        AssertAsync.staysTrue(controller != nil)
    }

    // MARK: - Is Paused Publisher

    func test_isPausedPublisher() {
        // Setup Recording publishers
        var recording = Record<Bool, Never>.Recording()

        // Setup the chain
        livestreamChannelController
            .isPausedPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: LivestreamChannelController? = livestreamChannelController
        livestreamChannelController = nil

        // Test initial state
        XCTAssertEqual(recording.output, [false])

        // Test pausing
        controller?.pause()
        
        // Use AssertAsync to wait for the async update
        AssertAsync {
            Assert.willBeEqual(recording.output, [false, true])
            Assert.willBeEqual(controller?.isPaused, true)
        }
    }

    func test_isPausedPublisher_keepsControllerAlive() {
        // Setup the chain
        livestreamChannelController
            .isPausedPublisher
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: LivestreamChannelController? = livestreamChannelController
        livestreamChannelController = nil

        // Assert controller is kept alive by the publisher.
        AssertAsync.staysTrue(controller != nil)
    }

    // MARK: - Skipped Messages Amount Publisher

    func test_skippedMessagesAmountPublisher() {
        // Setup Recording publishers
        var recording = Record<Int, Never>.Recording()
        
        // Enable counting skipped messages when paused
        livestreamChannelController.countSkippedMessagesWhenPaused = true

        // Setup the chain
        livestreamChannelController
            .skippedMessagesAmountPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: LivestreamChannelController? = livestreamChannelController
        livestreamChannelController = nil

        // Test initial state
        XCTAssertEqual(recording.output, [0])

        // Pause the controller to enable skipped message counting
        controller?.pause()
        
        // Simulate new messages from other users while paused
        let otherUserId = UserId.unique
        let messageFromOtherUser = ChatMessage.mock(id: .unique, cid: channelQuery.cid!, text: "Skipped message", author: .mock(id: otherUserId))
        
        let event = MessageNewEvent(
            user: .mock(id: otherUserId),
            message: messageFromOtherUser,
            channel: .mock(cid: channelQuery.cid!),
            createdAt: .unique,
            watcherCount: nil,
            unreadCount: nil
        )
        
        controller?.eventsController(
            EventsController(notificationCenter: client.eventNotificationCenter),
            didReceiveEvent: event
        )

        // Use AssertAsync to wait for the async update
        AssertAsync {
            Assert.willBeEqual(recording.output, [0, 1])
        }
    }

    func test_skippedMessagesAmountPublisher_keepsControllerAlive() {
        // Setup the chain
        livestreamChannelController
            .skippedMessagesAmountPublisher
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: LivestreamChannelController? = livestreamChannelController
        livestreamChannelController = nil

        // Assert controller is kept alive by the publisher.
        AssertAsync.staysTrue(controller != nil)
    }
}
