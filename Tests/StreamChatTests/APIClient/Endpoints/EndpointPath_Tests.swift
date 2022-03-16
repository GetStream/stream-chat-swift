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

    private func assertResultEncodingAndDecoding(_ value: EndpointPath, _ file: StaticString = #file, _ line: UInt = #line) {
        do {
            let encoded = try JSONEncoder.stream.encode(value)
            let result = try JSONDecoder.stream.decode(EndpointPath.self, from: encoded)
            XCTAssertEqual(result, value, file: file, line: line)
        } catch {
            XCTFail("Should not fail encoding/decoding", file: file, line: line)
        }
    }
}

extension EndpointPath: Equatable {}
public func == (_ lhs: EndpointPath, _ rhs: EndpointPath) -> Bool {
    switch (lhs, rhs) {
    case (.connect, .connect): return true
    case (.sync, .sync): return true
    case (.users, .users): return true
    case (.guest, .guest): return true
    case (.members, .members): return true
    case (.search, .search): return true
    case (.devices, .devices): return true
    case (.channels, .channels): return true
    case let (.createChannel(string1), .createChannel(string2)): return string1 == string2
    case let (.updateChannel(string1), .updateChannel(string2)): return string1 == string2
    case let (.deleteChannel(string1), .deleteChannel(string2)): return string1 == string2
    case let (.channelUpdate(string1), .channelUpdate(string2)): return string1 == string2
    case let (.muteChannel(bool1), .muteChannel(bool2)): return bool1 == bool2
    case let (.showChannel(string1, bool1), .showChannel(string2, bool2)): return string1 == string2 && bool1 == bool2
    case let (.truncateChannel(string1), .truncateChannel(string2)): return string1 == string2
    case let (.markChannelRead(string1), .markChannelRead(string2)): return string1 == string2
    case (.markAllChannelsRead, .markAllChannelsRead): return true
    case let (.channelEvent(string1), .channelEvent(string2)): return string1 == string2
    case let (.stopWatchingChannel(string1), .stopWatchingChannel(string2)): return string1 == string2
    case let (.pinnedMessages(string1), .pinnedMessages(string2)): return string1 == string2
    case let (.uploadAttachment(channelId1, type1), .uploadAttachment(channelId2, type2)): return channelId1 == channelId2 &&
        type1 ==
        type2
    case let (.sendMessage(channelId1), .sendMessage(channelId2)): return channelId1 == channelId2
    case let (.message(messageId1), .message(messageId2)): return messageId1 == messageId2
    case let (.editMessage(messageId1), .editMessage(messageId2)): return messageId1 == messageId2
    case let (.deleteMessage(messageId1), .deleteMessage(messageId2)): return messageId1 == messageId2
    case let (.replies(messageId1), .replies(messageId2)): return messageId1 == messageId2
    case let (.reactions(messageId1), .reactions(messageId2)): return messageId1 == messageId2
    case let (.addReaction(messageId1), .addReaction(messageId2)): return messageId1 == messageId2
    case let (
        .deleteReaction(messageId1, messageReactionType1),
        .deleteReaction(messageId2, messageReactionType2)
    ): return messageId1 == messageId2 && messageReactionType1 ==
        messageReactionType2
    case let (.messageAction(messageId1), .messageAction(messageId2)): return messageId1 == messageId2
    case (.banMember, .banMember): return true
    case let (.flagUser(bool1), .flagUser(bool2)): return bool1 == bool2
    case let (.flagMessage(bool1), .flagMessage(bool2)): return bool1 == bool2
    case let (.muteUser(bool1), .muteUser(bool2)): return bool1 == bool2
    default: return false
    }
}
