//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class NSManagedObject_Validation_Tests: XCTestCase {
    var database: DatabaseContainer!

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }

    func test_isValid_ReturnsTrue_WhenTheObjectIsNotDeleted() throws {
        guard let message = try createMessage() else {
            XCTFail()
            return
        }

        database.writableContext.performAndWait {
            XCTAssertTrue(message.isValid)
        }
    }

    func test_isValid_ReturnsFalse_WhenTheObjectIsDeleted() throws {
        guard let message = try createMessage() else {
            XCTFail()
            return
        }

        try database.writeSynchronously { session in
            session.delete(message: message)
        }

        database.writableContext.performAndWait {
            XCTAssertFalse(message.isValid)
        }
    }

    func test_deletedObject_doesNotCrash_whenAccessingDate() throws {
        guard let message = try createMessage() else {
            XCTFail()
            return
        }

        try database.writeSynchronously { session in
            session.delete(message: message)
        }

        // Should default to Date(timeIntervalSince1970: 0) for non optional values
        XCTAssertEqual(message.createdAt.bridgeDate, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(message.updatedAt.bridgeDate, Date(timeIntervalSince1970: 0))
        XCTAssertNil(message.deletedAt?.bridgeDate)
        XCTAssertNil(message.pinnedAt?.bridgeDate)
        XCTAssertNil(message.pinExpires?.bridgeDate)
        XCTAssertNil(message.locallyCreatedAt?.bridgeDate)
        XCTAssertNil(message.defaultSortingKey?.bridgeDate)
    }
}

private extension NSManagedObject_Validation_Tests {
    private func createMessage() throws -> MessageDTO? {
        let channelId = ChannelId(type: .messaging, id: "123")
        var message: MessageDTO?
        try database.createCurrentUser()
        try database.createChannel(cid: channelId)
        try database.writeSynchronously { session in
            message = try session.createNewMessage(in: channelId, text: "Hello", pinning: nil, quotedMessageId: nil)
        }
        return message
    }
}
