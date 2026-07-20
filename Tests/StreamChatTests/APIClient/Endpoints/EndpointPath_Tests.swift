//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    func test_getOG_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.getOG.shouldBeQueuedOffline)
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

    func test_reminders_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.reminders.shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.reminder("test_message").shouldBeQueuedOffline)
    }

    func test_unread_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.unreadCounts.shouldBeQueuedOffline)
    }

    func test_pushPreferences_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.updatePushNotificationPreferences.shouldBeQueuedOffline)
    }

    func test_getApp_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.getApp.shouldBeQueuedOffline)
    }

    func test_getApp_value() {
        XCTAssertEqual(EndpointPath.getApp.value, "/api/v2/app")
    }

    func test_devices_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.createDevice.shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.deleteDevice.shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.listDevices.shouldBeQueuedOffline)
    }

    func test_devices_value() {
        XCTAssertEqual(EndpointPath.createDevice.value, "/api/v2/devices")
        XCTAssertEqual(EndpointPath.deleteDevice.value, "/api/v2/devices")
        XCTAssertEqual(EndpointPath.listDevices.value, "/api/v2/devices")
    }

    func test_blockUsers_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.blockUsers.shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.unblockUsers.shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.getBlockedUsers.shouldBeQueuedOffline)
    }

    func test_blockUsers_value() {
        XCTAssertEqual(EndpointPath.blockUsers.value, "/api/v2/users/block")
    }

    func test_unblockUsers_value() {
        XCTAssertEqual(EndpointPath.unblockUsers.value, "/api/v2/users/unblock")
    }

    func test_getBlockedUsers_value() {
        XCTAssertEqual(EndpointPath.getBlockedUsers.value, "/api/v2/users/block")
    }

    func test_userGroups_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.listUserGroups.shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.searchUserGroups.shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.getUserGroup(id: "group").shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.createUserGroup.shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.updateUserGroup(id: "group").shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.deleteUserGroup(id: "group").shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.addUserGroupMembers(id: "group").shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.removeUserGroupMembers(id: "group").shouldBeQueuedOffline)
    }

    func test_userGroups_value() {
        XCTAssertEqual(EndpointPath.listUserGroups.value, "/api/v2/usergroups")
        XCTAssertEqual(EndpointPath.searchUserGroups.value, "/api/v2/usergroups/search")
        XCTAssertEqual(EndpointPath.createUserGroup.value, "/api/v2/usergroups")
        XCTAssertEqual(EndpointPath.getUserGroup(id: "backendsupport").value, "/api/v2/usergroups/backendsupport")
        XCTAssertEqual(EndpointPath.updateUserGroup(id: "backendsupport").value, "/api/v2/usergroups/backendsupport")
        XCTAssertEqual(EndpointPath.deleteUserGroup(id: "backendsupport").value, "/api/v2/usergroups/backendsupport")
        XCTAssertEqual(
            EndpointPath.addUserGroupMembers(id: "backendsupport").value,
            "/api/v2/usergroups/backendsupport/members"
        )
        XCTAssertEqual(
            EndpointPath.removeUserGroupMembers(id: "backendsupport").value,
            "/api/v2/usergroups/backendsupport/members/delete"
        )
    }

    func test_searchRoles_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.searchRoles.shouldBeQueuedOffline)
    }

    func test_searchRoles_value() {
        XCTAssertEqual(EndpointPath.searchRoles.value, "/api/v2/roles/search")
    }

    func test_pushPreferences_value() {
        let path = EndpointPath.updatePushNotificationPreferences.value
        XCTAssertEqual(path, "/api/v2/push_preferences")
    }

    func test_partialMemberUpdate_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.partialMemberUpdate(userId: "1", cid: .unique).shouldBeQueuedOffline)
    }

    func test_partialMemberUpdate_value() {
        let cid = ChannelId.unique
        let path = EndpointPath.partialMemberUpdate(userId: "1", cid: cid).value
        XCTAssertEqual(path, "channels/\(cid.apiPath)/member/1")
    }

    func test_drafts_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.drafts.shouldBeQueuedOffline)
    }

    func test_draftMessage_shouldBeQueuedOffline() {
        XCTAssertTrue(EndpointPath.draftMessage(.unique).shouldBeQueuedOffline)
    }

    func test_markChannelsDelivered_value() {
        let path = EndpointPath.markChannelsDelivered.value
        XCTAssertEqual(path, "channels/delivered")
    }

    // MARK: - Codable

    func test_isProperlyEncodedAndDecoded() throws {
        assertResultEncodingAndDecoding(.connect)
        assertResultEncodingAndDecoding(.sync)
        assertResultEncodingAndDecoding(.users)
        assertResultEncodingAndDecoding(.guest)
        assertResultEncodingAndDecoding(.members)
        assertResultEncodingAndDecoding(.partialMemberUpdate(userId: "1", cid: .init(type: .messaging, id: "2")))
        assertResultEncodingAndDecoding(.search)
        assertResultEncodingAndDecoding(.createDevice)
        assertResultEncodingAndDecoding(.deleteDevice)
        assertResultEncodingAndDecoding(.listDevices)
        assertResultEncodingAndDecoding(.threads)
        assertResultEncodingAndDecoding(.thread(messageId: "1"))
        assertResultEncodingAndDecoding(.updatePushNotificationPreferences)
        assertResultEncodingAndDecoding(.getApp)
        assertResultEncodingAndDecoding(.listUserGroups)
        assertResultEncodingAndDecoding(.searchUserGroups)
        assertResultEncodingAndDecoding(.createUserGroup)
        assertResultEncodingAndDecoding(.getUserGroup(id: "group"))
        assertResultEncodingAndDecoding(.updateUserGroup(id: "group"))
        assertResultEncodingAndDecoding(.deleteUserGroup(id: "group"))
        assertResultEncodingAndDecoding(.addUserGroupMembers(id: "group"))
        assertResultEncodingAndDecoding(.removeUserGroupMembers(id: "group"))
        assertResultEncodingAndDecoding(.searchRoles)

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
        assertResultEncodingAndDecoding(.markChannelsDelivered)
        assertResultEncodingAndDecoding(.channelEvent("channel_idq"))
        assertResultEncodingAndDecoding(.stopWatchingChannel(type: "messaging", id: "channel_idq"))
        assertResultEncodingAndDecoding(.pinnedMessages("channel_idq"))
        assertResultEncodingAndDecoding(.uploadChannelAttachment(channelId: "channel_id", type: "file"))

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
        assertResultEncodingAndDecoding(.blockUsers)
        assertResultEncodingAndDecoding(.unblockUsers)
        assertResultEncodingAndDecoding(.getBlockedUsers)

        assertResultEncodingAndDecoding(.polls)
        assertResultEncodingAndDecoding(.pollsQuery)
        assertResultEncodingAndDecoding(.poll(pollId: "test_poll"))
        assertResultEncodingAndDecoding(.pollVotes(pollId: "test_poll"))
        assertResultEncodingAndDecoding(.pollOptions(pollId: "test_poll"))
        assertResultEncodingAndDecoding(.pollOption(pollId: "test_poll", optionId: "option_id"))
        assertResultEncodingAndDecoding(.pollVoteInMessage(messageId: "test_message", pollId: "test_poll"))
        assertResultEncodingAndDecoding(.pollVote(messageId: "test_message", pollId: "test_poll", voteId: "test_vote"))

        assertResultEncodingAndDecoding(.drafts)
        assertResultEncodingAndDecoding(.draftMessage(ChannelId(type: .messaging, id: "test_channel")))
        
        assertResultEncodingAndDecoding(.reminders)
        assertResultEncodingAndDecoding(.reminder("test_message"))
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
