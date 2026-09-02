//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class EndpointPathTests: XCTestCase {
    func test_sendMessage_shouldBeQueuedOffline() throws {
        XCTAssertTrue(EndpointPath.sendMessage(type: "messaging", id: .unique).shouldBeQueuedOffline)
    }

    func test_updateMessage_shouldBeQueuedOffline() {
        XCTAssertTrue(EndpointPath.updateMessage(id: "").shouldBeQueuedOffline)
    }

    func test_updateMessagePartial_shouldBeQueuedOffline() {
        XCTAssertTrue(EndpointPath.updateMessagePartial(id: "").shouldBeQueuedOffline)
    }

    func test_createDraft_shouldBeQueuedOffline() {
        XCTAssertTrue(EndpointPath.createDraft(type: "messaging", id: "").shouldBeQueuedOffline)
    }

    func test_deleteMessage_shouldBeQueuedOffline() {
        XCTAssertTrue(EndpointPath.deleteMessage(id: "").shouldBeQueuedOffline)
    }

    func test_sendReaction_shouldBeQueuedOffline() {
        XCTAssertTrue(EndpointPath.sendReaction(id: "").shouldBeQueuedOffline)
    }

    func test_deleteReaction_shouldBeQueuedOffline() {
        XCTAssertTrue(EndpointPath.deleteReaction(id: "", type: "").shouldBeQueuedOffline)
    }

    func test_createChannel_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.createChannel("").shouldBeQueuedOffline)
    }

    func test_updateChannel_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.updateChannel("").shouldBeQueuedOffline)
    }

    func test_deleteChannel_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.deleteChannel(type: "", id: "").shouldBeQueuedOffline)
    }

    func test_banMember_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.banMember.shouldBeQueuedOffline)
    }

    func test_getOG_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.getOG.shouldBeQueuedOffline)
    }

    func test_getOG_buildsGeneratedEndpoint() {
        let endpoint: Endpoint<GetOGResponse> = .getOG(url: "https://getstream.io")

        XCTAssertEqual(endpoint.path.value, "/api/v2/og")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)

        let queryItems = endpoint.queryItems as? [String: String?]
        XCTAssertEqual(queryItems?["url"] ?? nil, "https://getstream.io")
    }

    func test_threads_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.queryThreads.shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.getThread(messageId: "1").shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.updateThreadPartial(messageId: "1").shouldBeQueuedOffline)
    }
    
    func test_polls_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.createPoll.shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.updatePollPartial(pollId: "test_poll").shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.deletePoll(pollId: "test_poll").shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.createPollOption(pollId: "test_poll").shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.queryPollVotes(pollId: "test_poll").shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.castPollVote(messageId: "test_message", pollId: "test_poll").shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.deletePollVote(messageId: "test_message", pollId: "test_poll", voteId: "test_vote").shouldBeQueuedOffline)
    }

    func test_reminders_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.queryReminders.shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.createReminder(messageId: "test_message").shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.updateReminder(messageId: "test_message").shouldBeQueuedOffline)
        XCTAssertFalse(EndpointPath.deleteReminder(messageId: "test_message").shouldBeQueuedOffline)
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

    func test_updateMemberPartial_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.updateMemberPartial(type: "messaging", id: "1").shouldBeQueuedOffline)
    }

    func test_updateMemberPartial_value() {
        let cid = ChannelId.unique
        let path = EndpointPath.updateMemberPartial(type: cid.type.rawValue, id: cid.id).value
        XCTAssertEqual(path, "/api/v2/chat/channels/\(cid.type.rawValue)/\(cid.id)/member")
    }

    func test_queryDrafts_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.queryDrafts.shouldBeQueuedOffline)
    }

    func test_getDraft_shouldNOTBeQueuedOffline() {
        XCTAssertFalse(EndpointPath.getDraft(type: "messaging", id: "").shouldBeQueuedOffline)
    }

    func test_deleteDraft_shouldBeQueuedOffline() {
        XCTAssertTrue(EndpointPath.deleteDraft(type: "messaging", id: "").shouldBeQueuedOffline)
    }

    func test_markDelivered_value() {
        let path = EndpointPath.markDelivered.value
        XCTAssertEqual(path, "/api/v2/chat/channels/delivered")
    }

    // MARK: - Codable

    func test_isProperlyEncodedAndDecoded() throws {
        assertResultEncodingAndDecoding(.custom("/custom-path"))
        assertResultEncodingAndDecoding(.connect)
        assertResultEncodingAndDecoding(.sync)
        assertResultEncodingAndDecoding(.queryUsers)
        assertResultEncodingAndDecoding(.updateUsersPartial)
        assertResultEncodingAndDecoding(.guest)
        assertResultEncodingAndDecoding(.queryMembers)
        assertResultEncodingAndDecoding(.updateMemberPartial(type: "messaging", id: "2"))
        assertResultEncodingAndDecoding(.search)
        assertResultEncodingAndDecoding(.createDevice)
        assertResultEncodingAndDecoding(.deleteDevice)
        assertResultEncodingAndDecoding(.listDevices)
        assertResultEncodingAndDecoding(.queryThreads)
        assertResultEncodingAndDecoding(.getThread(messageId: "1"))
        assertResultEncodingAndDecoding(.updateThreadPartial(messageId: "1"))
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
        assertResultEncodingAndDecoding(.deleteChannel(type: "messaging", id: "channel_idd"))
        assertResultEncodingAndDecoding(.channelUpdate("channel_idq"))
        assertResultEncodingAndDecoding(.hideChannel(type: "messaging", id: "channel_id"))
        assertResultEncodingAndDecoding(.showChannel(type: "messaging", id: "channel_id"))
        assertResultEncodingAndDecoding(.truncateChannel(type: "messaging", id: "channel_idq"))
        assertResultEncodingAndDecoding(.markChannelRead("channel_idq"))
        assertResultEncodingAndDecoding(.markAllChannelsRead)
        assertResultEncodingAndDecoding(.markDelivered)
        assertResultEncodingAndDecoding(.channelEvent("channel_idq"))
        assertResultEncodingAndDecoding(.stopWatchingChannel(type: "messaging", id: "channel_idq"))
        assertResultEncodingAndDecoding(.getPinnedMessages(type: "messaging", id: "channel_idq"))
        assertResultEncodingAndDecoding(.uploadChannelFile(type: "messaging", id: "channel_id"))

        assertResultEncodingAndDecoding(.sendMessage(type: "messaging", id: "the_id"))
        assertResultEncodingAndDecoding(.message("message_idm"))
        assertResultEncodingAndDecoding(.updateMessage(id: "message_ide"))
        assertResultEncodingAndDecoding(.updateMessagePartial(id: "message_idp"))
        assertResultEncodingAndDecoding(.createDraft(type: "messaging", id: "draft_channel"))
        assertResultEncodingAndDecoding(.deleteMessage(id: "message_idd"))
        assertResultEncodingAndDecoding(.replies("message_idr"))
        assertResultEncodingAndDecoding(.getReactions(id: "message_idre"))
        assertResultEncodingAndDecoding(.queryReactions(id: "message_idqre"))
        assertResultEncodingAndDecoding(.sendReaction(id: "message_ida"))
        assertResultEncodingAndDecoding(.deleteReaction(id: "message_id", type: "love"))
        assertResultEncodingAndDecoding(.messageAction("message_ida"))

        assertResultEncodingAndDecoding(.banMember)
        assertResultEncodingAndDecoding(.flagUser)
        assertResultEncodingAndDecoding(.flagMessage)
        assertResultEncodingAndDecoding(.blockUsers)
        assertResultEncodingAndDecoding(.unblockUsers)
        assertResultEncodingAndDecoding(.getBlockedUsers)

        assertResultEncodingAndDecoding(.createPoll)
        assertResultEncodingAndDecoding(.updatePollPartial(pollId: "test_poll"))
        assertResultEncodingAndDecoding(.deletePoll(pollId: "test_poll"))
        assertResultEncodingAndDecoding(.createPollOption(pollId: "test_poll"))
        assertResultEncodingAndDecoding(.queryPollVotes(pollId: "test_poll"))
        assertResultEncodingAndDecoding(.castPollVote(messageId: "test_message", pollId: "test_poll"))
        assertResultEncodingAndDecoding(.deletePollVote(messageId: "test_message", pollId: "test_poll", voteId: "test_vote"))

        assertResultEncodingAndDecoding(.queryDrafts)
        assertResultEncodingAndDecoding(.getDraft(type: "messaging", id: "draft_channel"))
        assertResultEncodingAndDecoding(.deleteDraft(type: "messaging", id: "draft_channel"))
        
        assertResultEncodingAndDecoding(.queryReminders)
        assertResultEncodingAndDecoding(.createReminder(messageId: "test_message"))
        assertResultEncodingAndDecoding(.updateReminder(messageId: "test_message"))
        assertResultEncodingAndDecoding(.deleteReminder(messageId: "test_message"))
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
