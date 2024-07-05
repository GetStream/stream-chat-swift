//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class EndpointPathTests: XCTestCase {
    func test_sendMessage_shouldBeQueuedOffline() throws {
        XCTAssertTrue(EndpointPath.sendMessage(.unique).shouldBeQueuedOffline)
    }

    func test_editMessage_shouldBeQueuedOffline() {
        XCTAssertTrue(EndpointPath.editMessage("").shouldBeQueuedOffline)
    }

    func test_deleteMessage_shouldBeQueuedOffline() {
        XCTAssertTrue(EndpointPath.deleteMessage("").shouldBeQueuedOffline)
    }
    
    func test_pinMessage_shouldBeQueuedOffline() {
        XCTAssertTrue(EndpointPath.pinMessage("").shouldBeQueuedOffline)
    }

    func test_addReaction_shouldBeQueuedOffline() {
        XCTAssertTrue(EndpointPath.addReaction("").shouldBeQueuedOffline)
    }

    func test_deleteReaction_shouldBeQueuedOffline() {
        XCTAssertTrue(EndpointPath.deleteReaction("", "").shouldBeQueuedOffline)
    }

    func test_createChannel_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.createChannel("").shouldBeQueuedOffline)
    }

    func test_updateChannel_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.updateChannel("").shouldBeQueuedOffline)
    }

    func test_deleteChannel_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.deleteChannel("").shouldBeQueuedOffline)
    }

    func test_banMember_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.banMember.shouldBeQueuedOffline)
    }

    func test_og_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.og.shouldBeQueuedOffline)
    }

    func test_threads_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.threads.shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.thread(messageId: "1").shouldBeQueuedOffline)
    }
    
    func test_polls_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.polls.shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.pollsQuery.shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.poll(pollId: "test_poll").shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.pollVotes(pollId: "test_poll").shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.pollOptions(pollId: "test_poll").shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.pollOption(pollId: "test_poll", optionId: "option_id").shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.pollVoteInMessage(messageId: "test_message", pollId: "test_poll").shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.pollVote(messageId: "test_message", pollId: "test_poll", voteId: "test_vote").shouldBeQueuedOffline)
    }

    func test_unread_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.unread.shouldBeQueuedOffline)
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
        assertResultEncodingAndDecoding(.threads)
        assertResultEncodingAndDecoding(.thread(messageId: "1"))
        assertResultEncodingAndDecoding(.appSettings)

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
        assertResultEncodingAndDecoding(.pinMessage("message_idp"))
        assertResultEncodingAndDecoding(.replies("message_idr"))
        assertResultEncodingAndDecoding(.reactions("message_idre"))
        assertResultEncodingAndDecoding(.addReaction("message_ida"))
        assertResultEncodingAndDecoding(.deleteReaction("message_id", MessageReactionType(rawValue: "love")))
        assertResultEncodingAndDecoding(.messageAction("message_ida"))

        assertResultEncodingAndDecoding(.banMember)
        assertResultEncodingAndDecoding(.flagUser(false))
        assertResultEncodingAndDecoding(.flagMessage(false))
        assertResultEncodingAndDecoding(.muteUser(false))
        assertResultEncodingAndDecoding(.blockUser)
        
        assertResultEncodingAndDecoding(.polls)
        assertResultEncodingAndDecoding(.pollsQuery)
        assertResultEncodingAndDecoding(.poll(pollId: "test_poll"))
        assertResultEncodingAndDecoding(.pollVotes(pollId: "test_poll"))
        assertResultEncodingAndDecoding(.pollOptions(pollId: "test_poll"))
        assertResultEncodingAndDecoding(.pollOption(pollId: "test_poll", optionId: "option_id"))
        assertResultEncodingAndDecoding(.pollVoteInMessage(messageId: "test_message", pollId: "test_poll"))
        assertResultEncodingAndDecoding(.pollVote(messageId: "test_message", pollId: "test_poll", voteId: "test_vote"))
    }
}

extension EndpointPathTests {
    private func assertResultEncodingAndDecoding(_ value: EndpointPath, _ file: StaticString = #filePath, _ line: UInt = #line) {
        do {
            let encoded = try JSONEncoder.stream.encode(value)
            let result = try JSONDecoder.stream.decode(EndpointPath.self, from: encoded)
            XCTAssertEqual(result.value, value.value, file: file, line: line)
        } catch {
            XCTFail("Should not fail encoding/decoding", file: file, line: line)
        }
    }
}
