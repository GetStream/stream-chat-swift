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

    // MARK: - Codable

    func test_isProperlyEncodedAndDecoded() throws {
        assertResultEncodingAndDecoding(.connect)
        assertResultEncodingAndDecoding(.sync)
        assertResultEncodingAndDecoding(.users)
        assertResultEncodingAndDecoding(.guest)
        assertResultEncodingAndDecoding(.members)
        assertResultEncodingAndDecoding(.search)
        assertResultEncodingAndDecoding(.devices)

        assertResultEncodingAndDecoding(.channels)
        assertResultEncodingAndDecoding(.createChannel("channel_idc"))
        assertResultEncodingAndDecoding(.updateChannel("channel_idu"))
        assertResultEncodingAndDecoding(.deleteChannel("channel_idd"))
        assertResultEncodingAndDecoding(.channelUpdate("channel_idq"))
        assertResultEncodingAndDecoding(.muteChannel(false))
        assertResultEncodingAndDecoding(.showChannel("channel_id", false))
        assertResultEncodingAndDecoding(.truncateChannel("channel_idq"))
        assertResultEncodingAndDecoding(.markChannelRead("channel_idq"))
        assertResultEncodingAndDecoding(.markAllChannelsRead)
        assertResultEncodingAndDecoding(.channelEvent("channel_idq"))
        assertResultEncodingAndDecoding(.stopWatchingChannel("channel_idq"))
        assertResultEncodingAndDecoding(.pinnedMessages("channel_idq"))
        assertResultEncodingAndDecoding(.uploadAttachment(channelId: "channel_id", type: "file"))

        assertResultEncodingAndDecoding(.sendMessage(ChannelId(type: .messaging, id: "the_id")))
        assertResultEncodingAndDecoding(.message("message_idm"))
        assertResultEncodingAndDecoding(.editMessage("message_ide"))
        assertResultEncodingAndDecoding(.deleteMessage("message_idd"))
        assertResultEncodingAndDecoding(.replies("message_idr"))
        assertResultEncodingAndDecoding(.reactions("message_idre"))
        assertResultEncodingAndDecoding(.addReaction("message_ida"))
        assertResultEncodingAndDecoding(.deleteReaction("message_id", MessageReactionType(rawValue: "love")))
        assertResultEncodingAndDecoding(.messageAction("message_ida"))

        assertResultEncodingAndDecoding(.banMember)
        assertResultEncodingAndDecoding(.flagUser(false))
        assertResultEncodingAndDecoding(.flagMessage(false))
        assertResultEncodingAndDecoding(.muteUser(false))
    }
}

extension EndpointPathTests {
    private func assertResultEncodingAndDecoding(_ value: EndpointPath, _ file: StaticString = #filePath, _ line: UInt = #line) {
        do {
            let encoded = try JSONEncoder.stream.encode(value)
            let result = try JSONDecoder.stream.decode(EndpointPath.self, from: encoded)
            XCTAssertEqual(result, value, file: file, line: line)
        } catch {
            XCTFail("Should not fail encoding/decoding", file: file, line: line)
        }
    }
}
