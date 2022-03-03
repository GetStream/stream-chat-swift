//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class EndpointPathTests: XCTestCase {
    func sendMessage_shouldBeQueuedOffline() throws {
        try XCTAssertTrue(EndpointPath.sendMessage(ChannelId(cid: "")).shouldBeQueuedOffline)
    }

    func editMessage_shouldBeQueuedOffline() {
        XCTAssertTrue(EndpointPath.editMessage("").shouldBeQueuedOffline)
    }

    func deleteMessage_shouldBeQueuedOffline() {
        XCTAssertTrue(EndpointPath.deleteMessage("").shouldBeQueuedOffline)
    }

    func addReaction_shouldBeQueuedOffline() {
        XCTAssertTrue(EndpointPath.addReaction("").shouldBeQueuedOffline)
    }

    func deleteReaction_shouldBeQueuedOffline() {
        XCTAssertTrue(EndpointPath.deleteReaction("", "").shouldBeQueuedOffline)
    }

    func createChannel_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.createChannel("").shouldBeQueuedOffline)
    }

    func updateChannel_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.updateChannel("").shouldBeQueuedOffline)
    }

    func deleteChannel_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.deleteChannel("").shouldBeQueuedOffline)
    }

    func banMember_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.banMember.shouldBeQueuedOffline)
    }
}
