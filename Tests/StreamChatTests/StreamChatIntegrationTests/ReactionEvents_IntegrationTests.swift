//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ReactionEvents_IntegrationTests: XCTestCase {
    var client: ChatClient!
    var currentUserId: UserId!

    let eventDecoder = EventDecoder()

    override func setUp() {
        super.setUp()

        var config = ChatClientConfig(apiKeyString: "Integration_Tests_Key")
        config.isLocalStorageEnabled = false
        config.isClientInActiveMode = false

        currentUserId = .unique
        client = ChatClient(
            config: config,
            environment: .withZeroEventBatchingPeriod
        )
        try! client.databaseContainer.createCurrentUser(id: currentUserId)
        client.connectUser(userInfo: .init(id: currentUserId), token: .development(userId: currentUserId))
    }

    func test_ReactionNewEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ReactionNew")
        let event = try eventDecoder.decode(from: json) as? ReactionNewEvent

        // For message to be received, we need to have channel:
        try client.databaseContainer.createChannel(
            cid: .init(type: .messaging, id: "general"),
            withMessages: true,
            withQuery: false
        )

        try client.databaseContainer.createMessage(
            id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779", cid: .init(type: .messaging, id: "general")
        )

        XCTAssertTrue(
            client.databaseContainer.viewContext.message(id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779")?.latestReactions
                .isEmpty ?? false
        )

        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeFalse(
                self.client.databaseContainer.viewContext.message(
                    id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779"
                )?.latestReactions.isEmpty ?? true
            )
        }
    }

    func test_ReactionUpdatedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ReactionUpdated")
        let event = try eventDecoder.decode(from: json) as? ReactionUpdatedEvent

        let newReactionJSON = XCTestCase.mockData(fromJSONFile: "ReactionNew")
        let newReactionEvent = try eventDecoder.decode(from: newReactionJSON) as? ReactionNewEvent
        let newReactionPayload = try XCTUnwrap(newReactionEvent?.reaction)

        // For message to be received, we need to have channel:
        try client.databaseContainer.createChannel(
            cid: .init(type: .messaging, id: "general"),
            withMessages: true,
            withQuery: false
        )

        let lastUpdateMessageTime = "2020-06-20 17:09:56 +0000"

        try client.databaseContainer.createMessage(
            id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779",
            latestReactions: [newReactionPayload],
            type: .regular
        )

        XCTAssertEqual(
            try client.databaseContainer.viewContext.message(
                id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779"
            )?.asModel().latestReactions.first?.updatedAt.description,
            lastUpdateMessageTime
        )

        let unwrappedUpdate = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedUpdate)

        AssertAsync {
            Assert.willBeEqual(
                try? self.client.databaseContainer.viewContext.message(
                    id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779"
                )?.asModel().latestReactions.first?.updatedAt.description,
                "2020-07-20 17:09:56 +0000"
            )
        }
    }

    func test_ReactionDeletedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ReactionDeleted")
        let event = try eventDecoder.decode(from: json) as? ReactionDeletedEvent

        // For message to be received, we need to have channel:
        try client.databaseContainer.createChannel(
            cid: .init(type: .messaging, id: "general"),
            withMessages: true,
            withQuery: false
        )

        try client.databaseContainer.createMessage(
            id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779", cid: .init(type: .messaging, id: "general")
        )

        XCTAssertTrue(
            client.databaseContainer.viewContext.message(id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779")?.latestReactions
                .isEmpty ?? false
        )

        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeFalse(
                self.client.databaseContainer.viewContext.message(
                    id: "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779"
                )?.latestReactions.isEmpty ?? true
            )
        }
    }
}
