//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageEvents_IntegrationTests: XCTestCase {
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

    func test_MessageNewEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageNew")
        let event = try eventDecoder.decode(from: json) as? MessageNewEvent

        // For message to be received, we need to have channel:
        try client.databaseContainer.createChannel(
            cid: .init(type: .messaging, id: "general"),
            withMessages: true,
            withQuery: false
        )

        let unwrappedEvent = try XCTUnwrap(event)
        let completionCalled = expectation(description: "completion called")
        client.eventNotificationCenter.process(unwrappedEvent) { completionCalled.fulfill() }

        wait(for: [completionCalled], timeout: defaultTimeout)

        AssertAsync {
            Assert.willNotBeNil(self.client.databaseContainer.viewContext.message(id: "1ff9f6d0-df70-4703-aef0-379f95ad7366"))
        }
    }

    func test_MessageUpdatedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageUpdated")
        let event = try eventDecoder.decode(from: json) as? MessageUpdatedEvent

        // For message to be received, we need to have channel:
        try client.databaseContainer.createChannel(
            cid: .init(type: .messaging, id: "general"),
            withMessages: true,
            withQuery: false
        )

        let lastUpdateMessageTime: Date = .unique

        try client.databaseContainer.createMessage(
            id: "1ff9f6d0-df70-4703-aef0-379f95ad7366",
            updatedAt: lastUpdateMessageTime,
            type: .regular
        )

        XCTAssertEqual(
            client.databaseContainer.viewContext.message(id: "1ff9f6d0-df70-4703-aef0-379f95ad7366")?.updatedAt.bridgeDate,
            lastUpdateMessageTime
        )

        let unwrappedUpdate = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedUpdate)

        AssertAsync {
            Assert.willBeEqual(
                self.client.databaseContainer.viewContext.message(id: "1ff9f6d0-df70-4703-aef0-379f95ad7366")?.updatedAt
                    .description,
                "2020-07-17 13:46:10 +0000"
            )
        }
    }

    func test_MessageDeletedEventPayload_isHandled() throws {
        let updateJSON = XCTestCase.mockData(fromJSONFile: "MessageDeleted")
        let updateMessageEvent = try eventDecoder.decode(from: updateJSON) as? MessageDeletedEvent

        // For message to be received, we need to have channel:
        try client.databaseContainer.createChannel(
            cid: .init(type: .messaging, id: "general"),
            withMessages: true,
            withQuery: false
        )

        try client.databaseContainer.createMessage(id: "1ff9f6d0-df70-4703-aef0-379f95ad7366", type: .regular)
        XCTAssertNotNil(client.databaseContainer.viewContext.message(id: "1ff9f6d0-df70-4703-aef0-379f95ad7366"))

        let unwrappedEvent = try XCTUnwrap(updateMessageEvent)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willNotBeNil(self.client.databaseContainer.viewContext.message(id: "1ff9f6d0-df70-4703-aef0-379f95ad7366"))
            Assert.willBeEqual(
                self.client.databaseContainer.viewContext.message(
                    id: "1ff9f6d0-df70-4703-aef0-379f95ad7366"
                )?.deletedAt?.description,
                "2020-07-17 13:49:48 +0000"
            )
        }
    }

    func test_NotificationMessageNewEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMessageNew")
        let event = try eventDecoder.decode(from: json) as? NotificationNewMessageEvent

        XCTAssertNil(client.databaseContainer.viewContext.message(id: "042772db-4af2-460d-beaa-1e49d1b8e3b9"))

        let unwrappedEvent = try XCTUnwrap(event)
        let completionCalled = expectation(description: "completion called")
        client.eventNotificationCenter.process(unwrappedEvent) { completionCalled.fulfill() }

        wait(for: [completionCalled], timeout: defaultTimeout)

        AssertAsync {
            Assert.willNotBeNil(self.client.databaseContainer.viewContext.message(id: "042772db-4af2-460d-beaa-1e49d1b8e3b9"))
        }
    }
}
