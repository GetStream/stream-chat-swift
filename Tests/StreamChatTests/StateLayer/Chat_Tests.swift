//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13.0, *)
final class Chat_Tests: XCTestCase {
    private var env: TestEnvironment!
    private var chat: Chat!
    private var channelId: ChannelId!
    private var currentUserId: UserId!
    private var expectedTestError: TestError!
    
    @MainActor override func setUp() async throws {
        channelId = ChannelId.unique
        currentUserId = .unique
        env = TestEnvironment()
        expectedTestError = TestError()
        try await setUpChat(usesMockedUpdaters: true)
    }

    override func tearDownWithError() throws {
        env.cleanUp()
        channelId = nil
        chat = nil
        currentUserId = nil
        env = nil
        expectedTestError = nil
    }
    
    // MARK: - Get
    
    func test_get_whenLocalStoreHasState_thenGetResetsState() async throws {
        // Existing state
        let initialChannelPayload = makeChannelPayload(
            messageCount: 10,
            memberCount: 9,
            watcherCount: 8,
            createdAtOffset: 0
        )
        env.client.mockAPIClient.test_mockResponseResult(.success(initialChannelPayload))
        try await setUpChat(usesMockedUpdaters: false)
        try await chat.get(watch: true)
        
        // Recreate the chat which simulates a new session and loading the state from the store
        try await setUpChat(usesMockedUpdaters: false)
        await XCTAssertEqual(10, chat.state.messages.count)
        await XCTAssertEqual(9, chat.state.members.count)
        await XCTAssertEqual(8, chat.state.watchers.count)
        
        let nextPayload = makeChannelPayload(
            messageCount: 3,
            memberCount: 2,
            watcherCount: 1,
            createdAtOffset: 0
        )
        env.client.mockAPIClient.test_mockResponseResult(.success(nextPayload))
        try await chat.get(watch: true)
        
        await XCTAssertEqual(3, chat.state.messages.count)
        await XCTAssertEqual(2, chat.state.members.count)
        await XCTAssertEqual(1, chat.state.watchers.count)
        await XCTAssertEqual(nextPayload.messages.map(\.id), chat.state.messages.map(\.id))
        await XCTAssertEqual(nextPayload.members.map(\.user?.id), chat.state.members.map(\.id))
        await XCTAssertEqual(nextPayload.watchers?.map(\.id), chat.state.watchers.map(\.id))
    }
    
    func test_get_whenLocalStoreHasNoState_thenGetFetchesState() async throws {
        try await setUpChat(usesMockedUpdaters: false)
        await XCTAssertEqual(0, chat.state.messages.count)
        await XCTAssertEqual(0, chat.state.members.count)
        await XCTAssertEqual(0, chat.state.watchers.count)
        
        let nextPayload = makeChannelPayload(
            messageCount: 3,
            memberCount: 2,
            watcherCount: 1,
            createdAtOffset: 0
        )
        env.client.mockAPIClient.test_mockResponseResult(.success(nextPayload))
        try await chat.get(watch: true)
        
        await XCTAssertEqual(3, chat.state.messages.count)
        await XCTAssertEqual(2, chat.state.members.count)
        await XCTAssertEqual(1, chat.state.watchers.count)
        await XCTAssertEqual(nextPayload.messages.map(\.id), chat.state.messages.map(\.id))
        await XCTAssertEqual(nextPayload.members.map(\.user?.id), chat.state.members.map(\.id))
        await XCTAssertEqual(nextPayload.watchers?.map(\.id), chat.state.watchers.map(\.id))
    }
    
    // MARK: - Deleting the Channel
    
    func test_delete_whenChannelUpdaterSucceeds_thenDeleteSucceeds() async throws {
        env.channelUpdaterMock.deleteChannel_completion_result = .success(())
        try await chat.delete()
    }
    
    func test_delete_whenChannelUpdaterFails_thenDeleteFails() async throws {
        env.channelUpdaterMock.deleteChannel_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.delete(), expectedTestError)
    }
    
    // MARK: - Disabling/Freezing the Channel
    
    func test_freeze_whenChannelUpdaterSucceeds_thenFreezeSucceeds() async throws {
        env.channelUpdaterMock.freezeChannel_completion_result = .success(())
        try await chat.freeze()
        XCTAssertEqual(channelId, env.channelUpdaterMock.freezeChannel_cid)
        XCTAssertEqual(true, env.channelUpdaterMock.freezeChannel_freeze)
    }
    
    func test_freeze_whenChannelUpdaterFails_thenFreezeFails() async throws {
        env.channelUpdaterMock.freezeChannel_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.freeze(), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.freezeChannel_cid)
        XCTAssertEqual(true, env.channelUpdaterMock.freezeChannel_freeze)
    }
    
    func test_unfreeze_whenChannelUpdaterSucceeds_thenUnfreezeSucceeds() async throws {
        env.channelUpdaterMock.freezeChannel_completion_result = .success(())
        try await chat.unfreeze()
        XCTAssertEqual(channelId, env.channelUpdaterMock.freezeChannel_cid)
        XCTAssertEqual(false, env.channelUpdaterMock.freezeChannel_freeze)
    }
    
    func test_unfreeze_whenChannelUpdaterFails_thenUnfreezeFails() async throws {
        env.channelUpdaterMock.freezeChannel_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.unfreeze(), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.freezeChannel_cid)
        XCTAssertEqual(false, env.channelUpdaterMock.freezeChannel_freeze)
    }
    
    // MARK: - Invites
    
    func test_acceptInvite_whenChannelUpdaterSucceeds_thenAcceptInviteSucceeds() async throws {
        env.channelUpdaterMock.acceptInvite_completion_result = .success(())
        try await chat.acceptInvite()
        XCTAssertEqual(channelId, env.channelUpdaterMock.acceptInvite_cid)
        XCTAssertEqual(nil, env.channelUpdaterMock.acceptInvite_message)
        
        env.channelUpdaterMock.acceptInvite_completion_result = .success(())
        try await chat.acceptInvite(with: "My system message")
        XCTAssertEqual(channelId, env.channelUpdaterMock.acceptInvite_cid)
        XCTAssertEqual("My system message", env.channelUpdaterMock.acceptInvite_message)
    }
    
    func test_acceptInvite_whenChannelUpdaterFails_thenAcceptInviteFails() async throws {
        env.channelUpdaterMock.acceptInvite_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.acceptInvite(), expectedTestError)
        await XCTAssertAsyncFailure(try await chat.acceptInvite(with: "My system message"), expectedTestError)
    }
    
    func test_inviteMembers_whenChannelUpdaterSucceeds_thenInviteMembersSucceeds() async throws {
        let memberIds: [UserId] = [.unique, .unique]
        env.channelUpdaterMock.inviteMembers_completion_result = .success(())
        try await chat.inviteMembers(memberIds)
        XCTAssertEqual(channelId, env.channelUpdaterMock.inviteMembers_cid)
        XCTAssertEqual(memberIds.sorted(), env.channelUpdaterMock.inviteMembers_userIds?.sorted())
    }
    
    func test_inviteMembers_whenChannelUpdaterFails_thenInviteMembersFails() async throws {
        let memberIds: [UserId] = [.unique, .unique]
        env.channelUpdaterMock.inviteMembers_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.inviteMembers(memberIds), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.inviteMembers_cid)
        XCTAssertEqual(memberIds.sorted(), env.channelUpdaterMock.inviteMembers_userIds?.sorted())
    }
    
    func test_rejectMembers_whenChannelUpdaterSucceeds_thenRejectMembersSucceeds() async throws {
        env.channelUpdaterMock.rejectInvite_completion_result = .success(())
        try await chat.rejectInvite()
        XCTAssertEqual(channelId, env.channelUpdaterMock.rejectInvite_cid)
    }
    
    func test_rejectMembers_whenChannelUpdaterFails_thenRejectMembersFails() async throws {
        env.channelUpdaterMock.rejectInvite_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.rejectInvite(), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.rejectInvite_cid)
    }
    
    // MARK: - Members
    
    func test_addMembers_whenChannelUpdaterSucceeds_thenAddMembersSucceeds() async throws {
        for hideHistory in [true, false] {
            env.channelUpdaterMock.addMembers_completion_result = .success(())
            let memberIds: [UserId] = [.unique, .unique]
            try await chat.addMembers(memberIds, systemMessage: "My system message", hideHistory: hideHistory)
            XCTAssertEqual(channelId, env.channelUpdaterMock.addMembers_cid)
            XCTAssertEqual(memberIds.sorted(), env.channelUpdaterMock.addMembers_userIds?.sorted())
            XCTAssertEqual("My system message", env.channelUpdaterMock.addMembers_message)
            XCTAssertEqual(hideHistory, env.channelUpdaterMock.addMembers_hideHistory)
            XCTAssertEqual(currentUserId, env.channelUpdaterMock.addMembers_currentUserId)
        }
    }
    
    func test_addMembers_whenChannelUpdaterFails_thenAddMembersSucceeds() async throws {
        for hideHistory in [true, false] {
            env.channelUpdaterMock.addMembers_completion_result = .failure(expectedTestError)
            let memberIds: [UserId] = [.unique, .unique]
            
            await XCTAssertAsyncFailure(
                try await chat.addMembers(memberIds, systemMessage: "My system message", hideHistory: hideHistory),
                expectedTestError
            )
            
            XCTAssertEqual(channelId, env.channelUpdaterMock.addMembers_cid)
            XCTAssertEqual(memberIds.sorted(), env.channelUpdaterMock.addMembers_userIds?.sorted())
            XCTAssertEqual("My system message", env.channelUpdaterMock.addMembers_message)
            XCTAssertEqual(hideHistory, env.channelUpdaterMock.addMembers_hideHistory)
            XCTAssertEqual(currentUserId, env.channelUpdaterMock.addMembers_currentUserId)
        }
    }
    
    func test_removeMembers_whenChannelUpdaterSucceeds_thenRemoveMembersSucceeds() async throws {
        env.channelUpdaterMock.removeMembers_completion_result = .success(())
        let memberIds: [UserId] = [.unique, .unique]
        try await chat.removeMembers(memberIds, systemMessage: "My system message")
        XCTAssertEqual(channelId, env.channelUpdaterMock.removeMembers_cid)
        XCTAssertEqual(memberIds.sorted(), env.channelUpdaterMock.removeMembers_userIds?.sorted())
        XCTAssertEqual("My system message", env.channelUpdaterMock.removeMembers_message)
        XCTAssertEqual(currentUserId, env.channelUpdaterMock.removeMembers_currentUserId)
    }
    
    func test_removeMembers_whenChannelUpdaterFails_thenRemoveMembersSucceeds() async throws {
        env.channelUpdaterMock.removeMembers_completion_result = .failure(expectedTestError)
        let memberIds: [UserId] = [.unique, .unique]
        
        await XCTAssertAsyncFailure(
            try await chat.removeMembers(memberIds, systemMessage: "My system message"),
            expectedTestError
        )
        
        XCTAssertEqual(channelId, env.channelUpdaterMock.removeMembers_cid)
        XCTAssertEqual(memberIds.sorted(), env.channelUpdaterMock.removeMembers_userIds?.sorted())
        XCTAssertEqual("My system message", env.channelUpdaterMock.removeMembers_message)
        XCTAssertEqual(currentUserId, env.channelUpdaterMock.removeMembers_currentUserId)
    }
    
    // MARK: - Member Moderation
    
    func test_banMember_whenMemberUpdaterSucceeds_thenBanMemberSucceeds() async throws {
        env.memberUpdaterMock.banMember_completion_result = .success(())
        let reason = "Test reason"
        let timeout = 5
        let memberId: UserId = .unique
        try await chat.banMember(memberId, reason: reason, timeout: timeout)
        XCTAssertEqual(channelId, env.memberUpdaterMock.banMember_cid)
        XCTAssertEqual(memberId, env.memberUpdaterMock.banMember_userId)
        XCTAssertEqual(reason, env.memberUpdaterMock.banMember_reason)
        XCTAssertEqual(timeout, env.memberUpdaterMock.banMember_timeoutInMinutes)
        XCTAssertEqual(false, env.memberUpdaterMock.banMember_shadow)
    }
    
    func test_banMember_whenMemberUpdaterFails_thenBanMemberSucceeds() async throws {
        env.memberUpdaterMock.banMember_completion_result = .failure(expectedTestError)
        let reason = "Test reason"
        let timeout = 5
        let memberId: UserId = .unique
        
        await XCTAssertAsyncFailure(
            try await chat.banMember(memberId, reason: reason, timeout: timeout),
            expectedTestError
        )
        
        XCTAssertEqual(channelId, env.memberUpdaterMock.banMember_cid)
        XCTAssertEqual(memberId, env.memberUpdaterMock.banMember_userId)
        XCTAssertEqual(reason, env.memberUpdaterMock.banMember_reason)
        XCTAssertEqual(timeout, env.memberUpdaterMock.banMember_timeoutInMinutes)
        XCTAssertEqual(false, env.memberUpdaterMock.banMember_shadow)
    }
    
    func test_shadowBanMember_whenMemberUpdaterSucceeds_thenShadowBanMemberSucceeds() async throws {
        env.memberUpdaterMock.banMember_completion_result = .success(())
        let reason = "Test reason"
        let timeout = 5
        let memberId: UserId = .unique
        try await chat.shadowBanMember(memberId, reason: reason, timeout: timeout)
        XCTAssertEqual(channelId, env.memberUpdaterMock.banMember_cid)
        XCTAssertEqual(memberId, env.memberUpdaterMock.banMember_userId)
        XCTAssertEqual(reason, env.memberUpdaterMock.banMember_reason)
        XCTAssertEqual(timeout, env.memberUpdaterMock.banMember_timeoutInMinutes)
        XCTAssertEqual(true, env.memberUpdaterMock.banMember_shadow)
    }
    
    func test_shadowBanMember_whenMemberUpdaterFails_thenShadowBanMemberSucceeds() async throws {
        env.memberUpdaterMock.banMember_completion_result = .failure(expectedTestError)
        let reason = "Test reason"
        let timeout = 5
        let memberId: UserId = .unique
        
        await XCTAssertAsyncFailure(
            try await chat.shadowBanMember(memberId, reason: reason, timeout: timeout),
            expectedTestError
        )
        
        XCTAssertEqual(channelId, env.memberUpdaterMock.banMember_cid)
        XCTAssertEqual(memberId, env.memberUpdaterMock.banMember_userId)
        XCTAssertEqual(reason, env.memberUpdaterMock.banMember_reason)
        XCTAssertEqual(timeout, env.memberUpdaterMock.banMember_timeoutInMinutes)
        XCTAssertEqual(true, env.memberUpdaterMock.banMember_shadow)
    }
    
    func test_unbanMember_whenMemberUpdaterSucceeds_thenUnbanMemberSucceeds() async throws {
        env.memberUpdaterMock.unbanMember_completion_result = .success(())
        let memberId: UserId = .unique
        try await chat.unbanMember(memberId)
        XCTAssertEqual(channelId, env.memberUpdaterMock.unbanMember_cid)
        XCTAssertEqual(memberId, env.memberUpdaterMock.unbanMember_userId)
    }
    
    func test_unbanMember_whenMemberUpdaterFails_thenUnbanMemberSucceeds() async throws {
        env.memberUpdaterMock.unbanMember_completion_result = .failure(expectedTestError)
        let memberId: UserId = .unique
        await XCTAssertAsyncFailure(try await chat.unbanMember(memberId), expectedTestError)
        XCTAssertEqual(channelId, env.memberUpdaterMock.unbanMember_cid)
        XCTAssertEqual(memberId, env.memberUpdaterMock.unbanMember_userId)
    }
    
    // MARK: - Messages
    
    func test_deleteMessage_whenMessageUpdaterSucceeds_thenDeleteMessageSucceeds() async throws {
        for hard in [true, false] {
            env.messageUpdaterMock.deleteMessage_completion_result = .success(())
            let messageId: MessageId = .unique
            try await chat.deleteMessage(messageId, hard: hard)
            XCTAssertEqual(messageId, env.messageUpdaterMock.deleteMessage_messageId)
            XCTAssertEqual(hard, env.messageUpdaterMock.deleteMessage_hard)
        }
    }
    
    func test_deleteMessage_whenMessageUpdaterFails_thenDeleteMessageSucceeds() async throws {
        for hard in [true, false] {
            env.messageUpdaterMock.deleteMessage_completion_result = .failure(expectedTestError)
            let messageId: MessageId = .unique
            await XCTAssertAsyncFailure(try await chat.deleteMessage(messageId, hard: hard), expectedTestError)
            XCTAssertEqual(messageId, env.messageUpdaterMock.deleteMessage_messageId)
            XCTAssertEqual(hard, env.messageUpdaterMock.deleteMessage_hard)
        }
    }
    
    func test_resendAttachment_whenAPIRequestSucceeds_thenResendAttachmentSucceeds() async throws {
        try await setUpChat(usesMockedUpdaters: false)
        
        try await env.client.mockDatabaseContainer.write { session in
            let dto = try session.saveChannel(payload: self.makeChannelPayload(messageCount: 1, createdAtOffset: 0))
            let messageId = try XCTUnwrap(dto.messages.first?.id)
            let attachmentId = AttachmentId(cid: self.channelId, messageId: messageId, index: 0)
            let attachment = AnyAttachmentPayload.mockImage
            let attachmentDto = try session.createNewAttachment(attachment: attachment, id: attachmentId)
            attachmentDto.localState = .uploadingFailed
        }
        
        let attachmentMessage = try await MainActor.run { try XCTUnwrap(chat.state.messages.first) }
        let attachmentId = AttachmentId(cid: channelId, messageId: attachmentMessage.id, index: 0)
        let uploadingState = try XCTUnwrap(attachmentMessage.attachment(with: attachmentId)?.uploadingState)
        XCTAssertEqual(LocalAttachmentState.uploadingFailed, uploadingState.state)
        
        env.client.mockAPIClient.uploadFile_completion_result = .success(.dummy())
        let result = try await chat.resendAttachment(attachmentId)
        XCTAssertEqual(nil, result.attachment.uploadingState?.state)
    }
    
    func test_resendAttachment_whenAPIRequestFails_thenResendAttachmentFails() async throws {
        try await setUpChat(usesMockedUpdaters: false)
        
        try await env.client.mockDatabaseContainer.write { session in
            let dto = try session.saveChannel(payload: self.makeChannelPayload(messageCount: 1, createdAtOffset: 0))
            let messageId = try XCTUnwrap(dto.messages.first?.id)
            let attachmentId = AttachmentId(cid: self.channelId, messageId: messageId, index: 0)
            let attachment = AnyAttachmentPayload.mockImage
            let attachmentDto = try session.createNewAttachment(attachment: attachment, id: attachmentId)
            attachmentDto.localState = .uploadingFailed
        }
        
        let attachmentMessage = try await MainActor.run { try XCTUnwrap(chat.state.messages.first) }
        let attachmentId = AttachmentId(cid: channelId, messageId: attachmentMessage.id, index: 0)
        var uploadingState = try XCTUnwrap(attachmentMessage.attachment(with: attachmentId)?.uploadingState)
        XCTAssertEqual(LocalAttachmentState.uploadingFailed, uploadingState.state)
        
        env.client.mockAPIClient.uploadFile_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(
            try await chat.resendAttachment(attachmentId),
            expectedTestError
        )
        
        uploadingState = try XCTUnwrap(attachmentMessage.attachment(with: attachmentId)?.uploadingState)
        XCTAssertEqual(LocalAttachmentState.uploadingFailed, uploadingState.state)
    }
    
    func test_resendMessage_whenAPIRequestSucceeds_thenSendMessageSucceeds() async throws {
        try await setUpChat(usesMockedUpdaters: false)
        await XCTAssertEqual(0, chat.state.messages.count)

        let typingIndicatorResponse = EmptyResponse()
        env.client.mockAPIClient.test_mockResponseResult(.success(typingIndicatorResponse))
        // Fail the send message call
        env.client.mockAPIClient.test_mockResponseResult(Result<MessagePayload.Boxed, Error>.failure(expectedTestError))
        let text = "Text"
        let messageId: MessageId = "abc"
        await XCTAssertAsyncFailure(
            try await chat.sendMessage(
                with: text,
                messageId: messageId
            ),
            MessageRepositoryError.failedToSendMessage(expectedTestError)
        )
        await XCTAssertEqual(1, chat.state.messages.count)
        await XCTAssertEqual(LocalMessageState.sendingFailed, chat.state.messages.first?.localState)
        
        // Resend and sending succeeds
        let apiResponse = MessagePayload.Boxed(
            message: .dummy(
                messageId: messageId,
                text: text
            )
        )
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResponse))
        let message = try await chat.resendMessage(messageId)
        
        XCTAssertEqual(text, message.text)
        await XCTAssertEqual(1, chat.state.messages.count)
        let messages = await chat.state.messages
        let stateMessage = try XCTUnwrap(messages.first)
        XCTAssertEqual(text, stateMessage.text)
        XCTAssertEqual(nil, stateMessage.localState)
    }
    
    func test_sendMessage_whenAPIRequestSucceeds_thenSendMessageSucceeds() async throws {
        try await setUpChat(usesMockedUpdaters: false)
        await XCTAssertEqual(0, chat.state.messages.count)

        let notificationExpectation = expectation(
            forNotification: .NewEventReceived,
            object: nil,
            notificationCenter: env.client.eventNotificationCenter
        )
        
        let typingIndicatorResponse = EmptyResponse()
        env.client.mockAPIClient.test_mockResponseResult(.success(typingIndicatorResponse))
        
        let text = "Text"
        let apiResponse = MessagePayload.Boxed(
            message: .dummy(
                messageId: "0",
                text: text
            )
        )
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResponse))
        let message = try await chat.sendMessage(
            with: apiResponse.message.text,
            messageId: apiResponse.message.id
        )
        
        #if swift(>=5.8)
        await fulfillment(of: [notificationExpectation], timeout: defaultTimeout)
        #else
        wait(for: [notificationExpectation], timeout: defaultTimeout)
        #endif
        
        XCTAssertEqual(text, message.text)
        await XCTAssertEqual(1, chat.state.messages.count)
        let messages = await chat.state.messages
        let stateMessage = try XCTUnwrap(messages.first)
        XCTAssertEqual(text, stateMessage.text)
        XCTAssertEqual(nil, stateMessage.localState)
    }
    
    func test_sendMessage_whenAPIRequestFails_thenSendMessageFails() async throws {
        try await setUpChat(usesMockedUpdaters: false)
        await XCTAssertEqual(0, chat.state.messages.count)
        
        let typingIndicatorResponse = EmptyResponse()
        env.client.mockAPIClient.test_mockResponseResult(.success(typingIndicatorResponse))
        
        let text = "Text"
        let apiResponse = MessagePayload.Boxed(
            message: .dummy(
                messageId: "0",
                text: text
            )
        )
        env.client.mockAPIClient.test_mockResponseResult(Result<MessagePayload.Boxed, Error>.failure(expectedTestError))
        await XCTAssertAsyncFailure(
            try await chat.sendMessage(
                with: apiResponse.message.text,
                messageId: apiResponse.message.id
            ),
            MessageRepositoryError.failedToSendMessage(expectedTestError)
        )
        let messages = await chat.state.messages
        XCTAssertEqual(1, messages.count)
        let stateMessage = try XCTUnwrap(messages.first)
        XCTAssertEqual(text, stateMessage.text)
        XCTAssertEqual(LocalMessageState.sendingFailed, stateMessage.localState)
    }
    
    func test_updateMessage_whenAPIRequestSucceeds_thenUpdateMessageSucceeds() async throws {
        try await env.client.databaseContainer.write { session in
            try session.saveChannel(payload: self.makeChannelPayload(messageCount: 1, createdAtOffset: 0))
        }
        
        try await setUpChat(usesMockedUpdaters: false)
        await XCTAssertEqual(1, chat.state.messages.count)
        let messages = await chat.state.messages
        let messageId = try XCTUnwrap(messages.first?.id)
        
        // Typing indicator and edit message
        env.client.mockAPIClient.test_mockResponseResult(.success(EmptyResponse()))
        env.client.mockAPIClient.test_mockResponseResult(.success(EmptyResponse()))
        
        let message = try await chat.updateMessage(messageId, text: "New Text")
        XCTAssertEqual("New Text", message.text)
        XCTAssertEqual(nil, message.localState)
    }
    
    // MARK: - Message Loading and State
    
    func test_restoreMessages_whenExistingMessages_thenStateUpdates() async throws {
        // DB has some older messages loaded
        let initialChannelPayload = makeChannelPayload(messageCount: 3, createdAtOffset: 0)
        try await env.client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: initialChannelPayload)
        }
        
        try await setUpChat(usesMockedUpdaters: false, loadState: false)
        
        // Accessing the state triggers loading the inital states
        await XCTAssertEqual(initialChannelPayload.messages.map(\.id), chat.state.messages.map(\.id))
    }
    
    func test_loadMessages_whenAPIRequestSucceeds_thenStateUpdates() async throws {
        try await setUpChat(usesMockedUpdaters: false)
        let pageSize = 2
        let channelPayload = makeChannelPayload(messageCount: pageSize, createdAtOffset: 0)
        env.client.mockAPIClient.test_mockResponseResult(.success(channelPayload))
        
        let result = try await chat.loadMessages(with: MessagesPagination(pageSize: pageSize))
        XCTAssertEqual(channelPayload.messages.map(\.id), result.map(\.id))
        await MainActor.run {
            XCTAssertEqual(channelPayload.messages.map(\.id), chat.state.messages.map(\.id))
            XCTAssertEqual(false, chat.state.hasLoadedAllOlderMessages)
            XCTAssertEqual(true, chat.state.hasLoadedAllNewerMessages)
            XCTAssertEqual(false, chat.state.isJumpingToMessage)
            XCTAssertEqual(false, chat.state.isLoadingOlderMessages)
            XCTAssertEqual(false, chat.state.isLoadingMiddleMessages)
            XCTAssertEqual(false, chat.state.isLoadingNewerMessages)
        }
    }
    
    func test_loadMessagesFirstPage_whenAPIRequestSucceeds_thenStateIsReset() async throws {
        try await setUpChat(usesMockedUpdaters: false)
        
        // DB has some older messages loaded
        try await env.client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: self.makeChannelPayload(messageCount: 5, createdAtOffset: 0))
        }
        
        // Load the first page which should reset the state
        let channelPayload = makeChannelPayload(messageCount: 3, createdAtOffset: 5)
        env.client.mockAPIClient.test_mockResponseResult(.success(channelPayload))
        try await chat.loadMessages(with: MessagesPagination(pageSize: 3, parameter: nil))
        
        await MainActor.run {
            XCTAssertEqual(channelPayload.messages.map(\.id), chat.state.messages.map(\.id))
            XCTAssertEqual(false, chat.state.hasLoadedAllOlderMessages)
            XCTAssertEqual(true, chat.state.hasLoadedAllNewerMessages)
            XCTAssertEqual(false, chat.state.isJumpingToMessage)
            XCTAssertEqual(false, chat.state.isLoadingOlderMessages)
            XCTAssertEqual(false, chat.state.isLoadingMiddleMessages)
            XCTAssertEqual(false, chat.state.isLoadingNewerMessages)
        }
    }
    
    func test_loadOlderMessages_whenAPIRequestSucceeds_thenStateUpdates() async throws {
        // DB has some messages loaded
        let initialChannelPayload = makeChannelPayload(messageCount: 5, createdAtOffset: 5)
        try await env.client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: initialChannelPayload)
        }
        
        try await setUpChat(usesMockedUpdaters: false)

        // Load older
        let channelPayload = makeChannelPayload(messageCount: 5, createdAtOffset: 0)
        env.client.mockAPIClient.test_mockResponseResult(.success(channelPayload))
        try await chat.loadOlderMessages()
        
        let expectedIds = (channelPayload.messages + initialChannelPayload.messages).map(\.id)
        await MainActor.run {
            XCTAssertEqual(expectedIds, chat.state.messages.map(\.id))
            XCTAssertEqual(true, chat.state.hasLoadedAllOlderMessages)
            XCTAssertEqual(true, chat.state.hasLoadedAllNewerMessages)
            XCTAssertEqual(false, chat.state.isJumpingToMessage)
            XCTAssertEqual(false, chat.state.isLoadingOlderMessages)
            XCTAssertEqual(false, chat.state.isLoadingMiddleMessages)
            XCTAssertEqual(false, chat.state.isLoadingNewerMessages)
        }
    }
    
    func test_loadNewerMessages_whenAPIRequestSucceeds_thenStateUpdates() async throws {
        try await setUpChat(usesMockedUpdaters: false)
        
        // Reset has loaded state since we always load newest messages
        let initialChannelPayload = makeChannelPayload(messageCount: 3, createdAtOffset: 0)
        env.client.mockAPIClient.test_mockResponseResult(.success(initialChannelPayload))
        try await chat.loadMessages(around: initialChannelPayload.messages[1].id, limit: 2)
        
        // Load newer
        let channelPayload = makeChannelPayload(messageCount: 3, createdAtOffset: 5)
        env.client.mockAPIClient.test_mockResponseResult(.success(channelPayload))
        try await chat.loadNewerMessages()
        
        let expectedIds = (initialChannelPayload.messages + channelPayload.messages).map(\.id)
        await MainActor.run {
            XCTAssertEqual(expectedIds, chat.state.messages.map(\.id))
            XCTAssertEqual(false, chat.state.hasLoadedAllOlderMessages)
            XCTAssertEqual(true, chat.state.hasLoadedAllNewerMessages)
            XCTAssertEqual(false, chat.state.isJumpingToMessage)
            XCTAssertEqual(false, chat.state.isLoadingOlderMessages)
            XCTAssertEqual(false, chat.state.isLoadingMiddleMessages)
            XCTAssertEqual(false, chat.state.isLoadingNewerMessages)
        }
    }
    
    func test_loadMessagesAround_whenAPIRequestSucceeds_thenStateUpdates() async throws {
        // DB has some older messages loaded
        let initialChannelPayload = makeChannelPayload(messageCount: 5, createdAtOffset: 0)
        try await env.client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: initialChannelPayload)
        }
        
        try await setUpChat(usesMockedUpdaters: false)
 
        // Jump to a message
        let channelPayload = makeChannelPayload(messageCount: 3, createdAtOffset: 10)
        env.client.mockAPIClient.test_mockResponseResult(.success(channelPayload))
        try await chat.loadMessages(around: channelPayload.messages[1].id, limit: 2)
        
        XCTAssertEqual(channelPayload.messages.map(\.id), await chat.state.messages.map(\.id))
        await MainActor.run {
            XCTAssertEqual(false, chat.state.hasLoadedAllOlderMessages)
            XCTAssertEqual(false, chat.state.hasLoadedAllNewerMessages)
            XCTAssertEqual(true, chat.state.isJumpingToMessage)
            XCTAssertEqual(false, chat.state.isLoadingOlderMessages)
            XCTAssertEqual(false, chat.state.isLoadingMiddleMessages)
            XCTAssertEqual(false, chat.state.isLoadingNewerMessages)
        }
    }
    
    // MARK: - Message Attachment Actions
    
    func test_sendMessageAction_whenTappingCancel_thenSendMessageActionSucceedsWithoutAPIRequest() async throws {
        try await setUpChat(usesMockedUpdaters: false)
        try await env.client.databaseContainer.write { session in
            let dto = try session.saveChannel(payload: self.makeChannelPayload(messageCount: 1, createdAtOffset: 0))
            dto.messages.first?.type = MessageType.ephemeral.rawValue
        }
        
        let messageId = try await MainActor.run { try XCTUnwrap(chat.state.messages.first?.id) }
        let action = AttachmentAction(name: "name", value: "cancel", style: .default, type: .button, text: "text")
        
        try await chat.sendMessageAction(in: messageId, action: action)
        let message = try await MainActor.run { try XCTUnwrap(chat.localMessage(for: messageId)) }
        XCTAssertNotNil(message.deletedAt)
        XCTAssertEqual(nil, env.client.mockAPIClient.request_endpoint, "Cancel should not make any API requests")
    }
    
    func test_sendMessageAction_whenAPIRequestSucceds_thenSendMessageActionSucceeds() async throws {
        try await setUpChat(usesMockedUpdaters: false)
        try await env.client.databaseContainer.write { session in
            let dto = try session.saveChannel(payload: self.makeChannelPayload(messageCount: 1, createdAtOffset: 0))
            dto.messages.first?.type = MessageType.ephemeral.rawValue
        }
        
        let messageId = try await MainActor.run { try XCTUnwrap(chat.state.messages.first?.id) }
        let action = AttachmentAction(name: "name", value: "value", style: .default, type: .button, text: "text")
        
        let apiResponse = MessagePayload.Boxed(message: .dummy(type: .ephemeral, messageId: messageId, text: "TextChanged"))
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResponse))
        try await chat.sendMessageAction(in: messageId, action: action)
        let message = try await MainActor.run { try XCTUnwrap(chat.localMessage(for: messageId)) }
        XCTAssertEqual(nil, message.deletedAt)
        XCTAssertEqual("TextChanged", message.text)
    }
    
    func test_sendMessageAction_whenAPIRequestFails_thenSendMessageActionFails() async throws {
        try await setUpChat(usesMockedUpdaters: false)
        try await env.client.databaseContainer.write { session in
            let dto = try session.saveChannel(payload: self.makeChannelPayload(messageCount: 1, createdAtOffset: 0))
            dto.messages.first?.type = MessageType.ephemeral.rawValue
        }
        
        let initialMessage = try await MainActor.run { try XCTUnwrap(chat.state.messages.first) }
        let messageId = initialMessage.id
        let action = AttachmentAction(name: "name", value: "value", style: .default, type: .button, text: "text")
        
        env.client.mockAPIClient.test_mockResponseResult(Result<MessagePayload.Boxed, Error>.failure(expectedTestError))
        await XCTAssertAsyncFailure(
            try await chat.sendMessageAction(in: messageId, action: action),
            expectedTestError
        )
        let message = try await MainActor.run { try XCTUnwrap(chat.localMessage(for: messageId)) }
        XCTAssertEqual(nil, message.deletedAt)
        XCTAssertEqual(initialMessage.text, message.text)
    }
    
    // MARK: - Message Flagging
    
    func test_flagMessageAction_whenMessageUpdaterSucceeds_thenFlagMessageActionSucceeds() async throws {
        let messageId: MessageId = .unique
        env.messageUpdaterMock.flagMessage_completion_result = .success(())
        try await chat.flagMessage(messageId)
        XCTAssertEqual(channelId, env.messageUpdaterMock.flagMessage_cid)
        XCTAssertEqual(messageId, env.messageUpdaterMock.flagMessage_messageId)
        XCTAssertEqual(true, env.messageUpdaterMock.flagMessage_flag)
    }
    
    func test_flagMessageAction_whenMessageUpdaterFails_thenFlagMessageActionSucceeds() async throws {
        let messageId: MessageId = .unique
        env.messageUpdaterMock.flagMessage_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.flagMessage(messageId), expectedTestError)
        XCTAssertEqual(channelId, env.messageUpdaterMock.flagMessage_cid)
        XCTAssertEqual(messageId, env.messageUpdaterMock.flagMessage_messageId)
        XCTAssertEqual(true, env.messageUpdaterMock.flagMessage_flag)
    }
    
    func test_unflagMessageAction_whenMessageUpdaterSucceeds_thenUnflagMessageActionSucceeds() async throws {
        let messageId: MessageId = .unique
        env.messageUpdaterMock.flagMessage_completion_result = .success(())
        try await chat.unflagMessage(messageId)
        XCTAssertEqual(channelId, env.messageUpdaterMock.flagMessage_cid)
        XCTAssertEqual(messageId, env.messageUpdaterMock.flagMessage_messageId)
        XCTAssertEqual(false, env.messageUpdaterMock.flagMessage_flag)
    }
    
    func test_unflagMessageAction_whenMessageUpdaterFails_thenUnflagMessageActionSucceeds() async throws {
        let messageId: MessageId = .unique
        env.messageUpdaterMock.flagMessage_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.unflagMessage(messageId), expectedTestError)
        XCTAssertEqual(channelId, env.messageUpdaterMock.flagMessage_cid)
        XCTAssertEqual(messageId, env.messageUpdaterMock.flagMessage_messageId)
        XCTAssertEqual(false, env.messageUpdaterMock.flagMessage_flag)
    }
    
    // MARK: - Message Rich Content
    
    func test_enrichURLAction_whenChannelUpdaterSucceeds_thenEnrichURLActionSucceeds() async throws {
        let url: URL = .unique()
        let expectedLinkAttachmentPayload = LinkAttachmentPayload(
            originalURL: url,
            title: "Chat API Documentation",
            text: "Stream, scalable news feeds and activity streams as a service.",
            author: "Stream",
            previewURL: TestImages.r2.url
        )
        env.channelUpdaterMock.enrichUrl_completion_result = .success(expectedLinkAttachmentPayload)
        let actualLinkAttachmentPayload = try await chat.enrichURL(url)
        XCTAssertEqual(url, env.channelUpdaterMock.enrichUrl_url)
        XCTAssertEqual(actualLinkAttachmentPayload, expectedLinkAttachmentPayload)
    }
    
    func test_enrichURLAction_whenChannelUpdaterFails_thenEnrichURLActionSucceeds() async throws {
        let url: URL = .unique()
        env.channelUpdaterMock.enrichUrl_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(_ = try await chat.enrichURL(url), expectedTestError)
        XCTAssertEqual(url, env.channelUpdaterMock.enrichUrl_url)
    }
    
    // MARK: - Message Pinning
    
    func test_pinMessage_whenSendingFailedAndAPIRequestSucceeds_thenPinMessageSucceeds() async throws {
        // Waiting after MessageSender
        try await setUpChat(usesMockedUpdaters: false)
        try await env.client.databaseContainer.write { session in
            let dto = try session.saveChannel(payload: self.makeChannelPayload(messageCount: 1, createdAtOffset: 0))
            dto.messages.first?.localMessageState = .sendingFailed
        }
        
        let messageId = try await MainActor.run { try XCTUnwrap(chat.state.messages.first?.id) }
        let apiResponse = MessagePayload.Boxed(
            message: .dummy(
                messageId: messageId,
                pinned: true,
                pinnedAt: Date(timeIntervalSinceReferenceDate: 0),
                pinExpires: nil
            )
        )
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResponse))
        let pinnedMessage = try await chat.pinMessage(messageId, pinning: .noExpiration)
        XCTAssertEqual(apiResponse.message.id, pinnedMessage.id)
        XCTAssertEqual(true, pinnedMessage.isPinned)
        XCTAssertEqual(apiResponse.message.pinnedAt, pinnedMessage.pinDetails?.pinnedAt)
        XCTAssertEqual(nil, pinnedMessage.pinDetails?.expiresAt)
        XCTAssertEqual(nil, pinnedMessage.localState)
    }
    
    func test_pinMessage_whenSyncingFailedAndAPIRequestSucceeds_thenPinMessageSucceeds() async throws {
        // Waiting after MessageEditor
        try await setUpChat(usesMockedUpdaters: false)
        try await env.client.databaseContainer.write { session in
            let dto = try session.saveChannel(payload: self.makeChannelPayload(messageCount: 1, createdAtOffset: 0))
            dto.messages.first?.localMessageState = .syncingFailed
        }
        
        let messageId = try await MainActor.run { try XCTUnwrap(chat.state.messages.first?.id) }
        env.client.mockAPIClient.test_mockResponseResult(.success(EmptyResponse()))
        let pinnedMessage = try await chat.pinMessage(messageId, pinning: .noExpiration)
        XCTAssertEqual(messageId, pinnedMessage.id)
        XCTAssertEqual(true, pinnedMessage.isPinned)
        XCTAssertEqual(nil, pinnedMessage.localState)
    }
    
    func test_unpinMessage_whenSendingFailedAndAPIRequestSucceeds_thenPinMessageSucceeds() async throws {
        // Waiting after MessageSender
        try await setUpChat(usesMockedUpdaters: false)
        try await env.client.databaseContainer.write { session in
            let dto = try session.saveChannel(payload: self.makeChannelPayload(messageCount: 1, createdAtOffset: 0))
            dto.messages.first?.localMessageState = .sendingFailed
            dto.messages.first?.pinned = true
        }
        
        let messageId = try await MainActor.run { try XCTUnwrap(chat.state.messages.first?.id) }
        let apiResponse = MessagePayload.Boxed(
            message: .dummy(
                messageId: messageId,
                pinned: false
            )
        )
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResponse))
        let unpinnedMessage = try await chat.unpinMessage(messageId)
        XCTAssertEqual(messageId, unpinnedMessage.id)
        XCTAssertEqual(false, unpinnedMessage.isPinned)
        XCTAssertEqual(nil, unpinnedMessage.localState)
    }
    
    func test_unpinMessage_whenSyncingFailedAndAPIRequestSucceeds_thenPinMessageSucceeds() async throws {
        // Waiting after MessageEditor
        try await setUpChat(usesMockedUpdaters: false)
        try await env.client.databaseContainer.write { session in
            let dto = try session.saveChannel(payload: self.makeChannelPayload(messageCount: 1, createdAtOffset: 0))
            dto.messages.first?.localMessageState = .syncingFailed
            dto.messages.first?.pinned = true
        }
        
        let messageId = try await MainActor.run { try XCTUnwrap(chat.state.messages.first?.id) }
        env.client.mockAPIClient.test_mockResponseResult(.success(EmptyResponse()))
        let unpinnedMessage = try await chat.unpinMessage(messageId)
        XCTAssertEqual(messageId, unpinnedMessage.id)
        XCTAssertEqual(false, unpinnedMessage.isPinned)
        XCTAssertEqual(nil, unpinnedMessage.localState)
    }
    
    // TODO: not done
    func test_loadPinnedMessagesAction_whenAPIRequestSucceeds_thenLoadPinnedMessagesActionSucceeds() async throws {
        // loadPinnedMessages(for pagination: PinnedMessagesPagination? = nil, sort: [Sorting<PinnedMessagesSortingKey>] = [], limit: Int = .messagesPageSize)
    }
    
    // TODO: not done
    func test_loadPinnedMessagesAction_whenAPIRequestFails_thenLoadPinnedMessagesActionSucceeds() async throws {
        // loadPinnedMessages(for pagination: PinnedMessagesPagination? = nil, sort: [Sorting<PinnedMessagesSortingKey>] = [], limit: Int = .messagesPageSize)
    }
    
    // MARK: - Message Reactions
    
    func test_deleteReactionAction_whenMessageUpdaterSucceeds_thenDeleteReactionActionSucceeds() async throws {
        let messageId: MessageId = .unique
        let reactionType: MessageReactionType = .init(rawValue: "like")
        env.messageUpdaterMock.deleteReaction_completion_result = .success(())
        try await chat.deleteReaction(from: messageId, with: .init(rawValue: "like"))
        XCTAssertEqual(messageId, env.messageUpdaterMock.deleteReaction_messageId)
        XCTAssertEqual(reactionType, env.messageUpdaterMock.deleteReaction_type)
    }
    
    func test_deleteReactionAction_whenMessageUpdaterFails_thenDeleteReactionActionSucceeds() async throws {
        let messageId: MessageId = .unique
        let reactionType: MessageReactionType = .init(rawValue: "like")
        env.messageUpdaterMock.deleteReaction_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(
            try await chat.deleteReaction(from: messageId, with: .init(rawValue: "like")),
            expectedTestError
        )
        XCTAssertEqual(messageId, env.messageUpdaterMock.deleteReaction_messageId)
        XCTAssertEqual(reactionType, env.messageUpdaterMock.deleteReaction_type)
    }
    
    // MARK: - Message Translations
    
    func test_translateMessageStateAction_whenMessageUpdaterSucceeds_thenTranslateMessageActionSucceeds() async throws {
        let messageId: MessageId = .unique
        let text: String = "Test message"
        let createdAt: Date = .unique
        let language: TranslationLanguage = .turkish
        let message: ChatMessage = .mock(
            id: messageId,
            cid: channelId,
            text: text,
            author: .mock(id: currentUserId),
            createdAt: createdAt,
            isSentByCurrentUser: true
        )
        env.messageUpdaterMock.translate_completion_result = .success(message)
        try await chat.translateMessage(messageId, to: language)
        XCTAssertEqual(messageId, env.messageUpdaterMock.translate_messageId)
        XCTAssertEqual(language, env.messageUpdaterMock.translate_language)
    }
    
    func test_translateMessageStateAction_whenMessageUpdaterFails_thenTranslateMessageActionSucceeds() async throws {
        let messageId: MessageId = .unique
        let _: String = "Test message"
        let _: Date = .unique
        let language: TranslationLanguage = .turkish
        env.messageUpdaterMock.translate_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(
            _ = try await chat.translateMessage(messageId, to: language),
            expectedTestError
        )
        XCTAssertEqual(messageId, env.messageUpdaterMock.translate_messageId)
        XCTAssertEqual(language, env.messageUpdaterMock.translate_language)
    }
    
    // MARK: - Muting or Hiding the Channel
    
    func test_muteAction_whenChannelUpdaterSucceeds_thenMuteActionSucceeds() async throws {
        for expiration in [nil, 10] {
            env.channelUpdaterMock.muteChannel_completion_result = .success(())
            try await chat.mute(expiration: expiration)
            XCTAssertEqual(channelId, env.channelUpdaterMock.muteChannel_cid)
            XCTAssertEqual(expiration, env.channelUpdaterMock.muteChannel_expiration)
            XCTAssertEqual(true, env.channelUpdaterMock.muteChannel_mute)
        }
    }
    
    func test_muteAction_whenChannelUpdaterFails_thenMuteActionSucceeds() async throws {
        for expiration in [nil, 10] {
            env.channelUpdaterMock.muteChannel_completion_result = .failure(expectedTestError)
            await XCTAssertAsyncFailure(try await chat.mute(expiration: expiration), expectedTestError)
            XCTAssertEqual(channelId, env.channelUpdaterMock.muteChannel_cid)
            XCTAssertEqual(expiration, env.channelUpdaterMock.muteChannel_expiration)
            XCTAssertEqual(true, env.channelUpdaterMock.muteChannel_mute)
        }
    }
    
    func test_hideAction_whenChannelUpdaterSucceeds_thenHideActionSucceeds() async throws {
        for clearHistory in [true, false] {
            env.channelUpdaterMock.hideChannel_completion_result = .success(())
            try await chat.hide(clearHistory: clearHistory)
            XCTAssertEqual(channelId, env.channelUpdaterMock.hideChannel_cid)
            XCTAssertEqual(clearHistory, env.channelUpdaterMock.hideChannel_clearHistory)
        }
    }
    
    func test_hideAction_whenChannelUpdaterFails_thenHideActionSucceeds() async throws {
        for clearHistory in [true, false] {
            env.channelUpdaterMock.hideChannel_completion_result = .failure(expectedTestError)
            await XCTAssertAsyncFailure(try await chat.hide(clearHistory: clearHistory), expectedTestError)
            XCTAssertEqual(channelId, env.channelUpdaterMock.hideChannel_cid)
            XCTAssertEqual(clearHistory, env.channelUpdaterMock.hideChannel_clearHistory)
        }
    }
    
    func test_showAction_whenChannelUpdaterSucceeds_thenShowActionSucceeds() async throws {
        env.channelUpdaterMock.showChannel_completion_result = .success(())
        try await chat.show()
        XCTAssertEqual(channelId, env.channelUpdaterMock.showChannel_cid)
    }
    
    func test_hideAction_whenChannelUpdaterFails_thenShowActionSucceeds() async throws {
        env.channelUpdaterMock.showChannel_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.show(), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.showChannel_cid)
    }
    
    // MARK: - Throttling and Slow Mode
    
    func test_enableSlowModeAction_whenChannelUpdaterSucceeds_thenEnableSlowModeActionSucceeds() async throws {
        let cooldownDuration = 10
        env.channelUpdaterMock.enableSlowMode_completion_result = .success(())
        try await chat.enableSlowMode(cooldownDuration: cooldownDuration)
        XCTAssertEqual(channelId, env.channelUpdaterMock.enableSlowMode_cid)
        XCTAssertEqual(cooldownDuration, env.channelUpdaterMock.enableSlowMode_cooldownDuration)
    }
    
    func test_enableSlowModeAction_whenChannelUpdaterFails_thenEnableSlowModeActionSucceeds() async throws {
        let cooldownDuration = 10
        env.channelUpdaterMock.enableSlowMode_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.enableSlowMode(cooldownDuration: cooldownDuration), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.enableSlowMode_cid)
        XCTAssertEqual(cooldownDuration, env.channelUpdaterMock.enableSlowMode_cooldownDuration)
    }
    
    func test_disableSlowModeAction_whenChannelUpdaterSucceeds_thenDisableSlowModeActionSucceeds() async throws {
        env.channelUpdaterMock.enableSlowMode_completion_result = .success(())
        try await chat.disableSlowMode()
        XCTAssertEqual(channelId, env.channelUpdaterMock.enableSlowMode_cid)
        XCTAssertEqual(0, env.channelUpdaterMock.enableSlowMode_cooldownDuration)
    }
    
    func test_disableSlowModeAction_whenChannelUpdaterFails_thenDisableSlowModeActionSucceeds() async throws {
        env.channelUpdaterMock.enableSlowMode_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.disableSlowMode(), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.enableSlowMode_cid)
        XCTAssertEqual(0, env.channelUpdaterMock.enableSlowMode_cooldownDuration)
    }
    
    // MARK: - Truncating the Channel
    
    func test_truncateAction_whenChannelUpdaterSucceeds_thenTruncateActionSucceeds() async throws {
        env.channelUpdaterMock.truncateChannel_completion_result = .success(())
        
        var systemMessage: String?
        var hardDelete = true
        var skipPush = true
        try await chat.truncate(systemMessage: systemMessage, hardDelete: hardDelete, skipPush: skipPush)
        XCTAssertEqual(channelId, env.channelUpdaterMock.truncateChannel_cid)
        XCTAssertEqual(skipPush, env.channelUpdaterMock.truncateChannel_skipPush)
        XCTAssertEqual(hardDelete, env.channelUpdaterMock.truncateChannel_hardDelete)
        XCTAssertEqual(systemMessage, env.channelUpdaterMock.truncateChannel_systemMessage)
        
        systemMessage = "Test message"
        hardDelete = true
        skipPush = true
        try await chat.truncate(systemMessage: systemMessage, hardDelete: hardDelete, skipPush: skipPush)
        XCTAssertEqual(channelId, env.channelUpdaterMock.truncateChannel_cid)
        XCTAssertEqual(skipPush, env.channelUpdaterMock.truncateChannel_skipPush)
        XCTAssertEqual(hardDelete, env.channelUpdaterMock.truncateChannel_hardDelete)
        XCTAssertEqual(systemMessage, env.channelUpdaterMock.truncateChannel_systemMessage)
        
        systemMessage = nil
        hardDelete = false
        skipPush = false
        try await chat.truncate(systemMessage: systemMessage, hardDelete: hardDelete, skipPush: skipPush)
        XCTAssertEqual(channelId, env.channelUpdaterMock.truncateChannel_cid)
        XCTAssertEqual(skipPush, env.channelUpdaterMock.truncateChannel_skipPush)
        XCTAssertEqual(hardDelete, env.channelUpdaterMock.truncateChannel_hardDelete)
        XCTAssertEqual(systemMessage, env.channelUpdaterMock.truncateChannel_systemMessage)
        
        systemMessage = "Test message"
        hardDelete = false
        skipPush = false
        try await chat.truncate(systemMessage: systemMessage, hardDelete: hardDelete, skipPush: skipPush)
        XCTAssertEqual(channelId, env.channelUpdaterMock.truncateChannel_cid)
        XCTAssertEqual(skipPush, env.channelUpdaterMock.truncateChannel_skipPush)
        XCTAssertEqual(hardDelete, env.channelUpdaterMock.truncateChannel_hardDelete)
        XCTAssertEqual(systemMessage, env.channelUpdaterMock.truncateChannel_systemMessage)
    }
    
    func test_truncateAction_whenChannelUpdaterFails_thenTruncateActionSucceeds() async throws {
        env.channelUpdaterMock.truncateChannel_completion_result = .failure(expectedTestError)
        
        var systemMessage: String?
        var hardDelete = true
        var skipPush = true
        await XCTAssertAsyncFailure(try await chat.truncate(systemMessage: systemMessage, hardDelete: hardDelete, skipPush: skipPush), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.truncateChannel_cid)
        XCTAssertEqual(skipPush, env.channelUpdaterMock.truncateChannel_skipPush)
        XCTAssertEqual(hardDelete, env.channelUpdaterMock.truncateChannel_hardDelete)
        XCTAssertEqual(systemMessage, env.channelUpdaterMock.truncateChannel_systemMessage)
        
        systemMessage = "Test message"
        hardDelete = true
        skipPush = true
        await XCTAssertAsyncFailure(try await chat.truncate(systemMessage: systemMessage, hardDelete: hardDelete, skipPush: skipPush), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.truncateChannel_cid)
        XCTAssertEqual(skipPush, env.channelUpdaterMock.truncateChannel_skipPush)
        XCTAssertEqual(hardDelete, env.channelUpdaterMock.truncateChannel_hardDelete)
        XCTAssertEqual(systemMessage, env.channelUpdaterMock.truncateChannel_systemMessage)
        
        systemMessage = nil
        hardDelete = false
        skipPush = false
        await XCTAssertAsyncFailure(try await chat.truncate(systemMessage: systemMessage, hardDelete: hardDelete, skipPush: skipPush), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.truncateChannel_cid)
        XCTAssertEqual(skipPush, env.channelUpdaterMock.truncateChannel_skipPush)
        XCTAssertEqual(hardDelete, env.channelUpdaterMock.truncateChannel_hardDelete)
        XCTAssertEqual(systemMessage, env.channelUpdaterMock.truncateChannel_systemMessage)
        
        systemMessage = "Test message"
        hardDelete = false
        skipPush = false
        await XCTAssertAsyncFailure(try await chat.truncate(systemMessage: systemMessage, hardDelete: hardDelete, skipPush: skipPush), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.truncateChannel_cid)
        XCTAssertEqual(skipPush, env.channelUpdaterMock.truncateChannel_skipPush)
        XCTAssertEqual(hardDelete, env.channelUpdaterMock.truncateChannel_hardDelete)
        XCTAssertEqual(systemMessage, env.channelUpdaterMock.truncateChannel_systemMessage)
    }
    
    // MARK: - Watching the Channel
    
    func test_startWatchingAction_whenChannelUpdaterSucceeds_thenStartWatchingActionSucceeds() async throws {
        env.channelUpdaterMock.startWatching_completion_result = .success(())
        try await chat.watch()
        XCTAssertEqual(channelId, env.channelUpdaterMock.startWatching_cid)
    }
    
    func test_startWatchingAction_whenChannelUpdaterFails_thenStartWatchingActionSucceeds() async throws {
        env.channelUpdaterMock.startWatching_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.watch(), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.startWatching_cid)
    }
    
    func test_stopWatchingAction_whenChannelUpdaterSucceeds_thenStopWatchingActionSucceeds() async throws {
        env.channelUpdaterMock.stopWatching_completion_result = .success(())
        try await chat.stopWatching()
        XCTAssertEqual(channelId, env.channelUpdaterMock.stopWatching_cid)
    }
    
    func test_stopWatchingAction_whenChannelUpdaterFails_thenStopWatchingActionSucceeds() async throws {
        env.channelUpdaterMock.stopWatching_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.stopWatching(), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.stopWatching_cid)
    }
    
    // MARK: - Test Data
    
    /// Configures chat for testing.
    ///
    /// - Parameter usesMockedChannelUpdater: Set it for false for tests which need to update the local DB and simulate API requests.
    @MainActor private func setUpChat(
        usesMockedUpdaters: Bool,
        loadState: Bool = true,
        loggedIn: Bool = true
    ) async throws {
        chat = Chat(
            channelQuery: ChannelQuery(cid: channelId),
            messageOrdering: .bottomToTop,
            memberSorting: [Sorting(key: .createdAt, isAscending: true)],
            client: env.client,
            environment: env.chatEnvironment(usesMockedUpdaters: usesMockedUpdaters)
        )
        if loadState {
            _ = chat.state
        }
        if loggedIn {
            env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
            try await env.client.databaseContainer.write { session in
                guard session.currentUser == nil else { return }
                try session.saveCurrentUser(
                    payload: .dummy(userId: self.currentUserId, role: .admin)
                )
            }
        }
        try await env.client.databaseContainer.write { session in
            guard session.channel(cid: self.channelId) == nil else { return }
            try session.saveChannel(payload: self.makeChannelPayload(messageCount: 0, createdAtOffset: 0))
        }
    }
    
    private func makeChannelPayload(
        messageCount: Int,
        memberCount: Int = 0,
        watcherCount: Int = 0,
        createdAtOffset: Int
    ) -> ChannelPayload {
        // Note that message pagination relies on createdAt and cid
        let messages: [MessagePayload] = (0..<messageCount)
            .map {
                .dummy(
                    messageId: "\($0 + createdAtOffset)",
                    createdAt: Date(timeIntervalSinceReferenceDate: TimeInterval($0 + createdAtOffset)),
                    cid: channelId
                )
            }
        let members: [MemberPayload] = (0..<memberCount)
            .map {
                .dummy(
                    user: .dummy(
                        userId: "\($0 + createdAtOffset)"
                    ),
                    createdAt: Date(timeIntervalSinceReferenceDate: TimeInterval($0 + createdAtOffset))
                )
            }
        let watchers: [UserPayload] = (0..<watcherCount)
            .map {
                .dummy(userId: "\($0 + createdAtOffset)")
            }
        return ChannelPayload.dummy(
            channel: .dummy(cid: channelId),
            watchers: watchers,
            members: members,
            messages: messages
        )
    }
}

@available(iOS 13.0, *)
extension Chat_Tests {
    final class TestEnvironment {
        let client: ChatClient_Mock
        private(set) var chatState: ChatState!
        private(set) var channelUpdater: ChannelUpdater!
        private(set) var channelUpdaterMock: ChannelUpdater_Mock!
        private(set) var memberUpdater: ChannelMemberUpdater!
        private(set) var memberUpdaterMock: ChannelMemberUpdater_Mock!
        private(set) var messageUpdater: MessageUpdater!
        private(set) var messageUpdaterMock: MessageUpdater_Mock!
        private(set) var readStateSender: Chat.ReadStateSender!
        private(set) var typingEventsSender: TypingEventsSender!
        private(set) var typingEventsSenderMock: TypingEventsSender_Mock!
        
        func cleanUp() {
            client.cleanUp()
            channelUpdaterMock?.cleanUp()
            memberUpdaterMock?.cleanUp()
            messageUpdaterMock?.cleanUp()
            typingEventsSenderMock?.cleanUp()
        }
        
        init() {
            var config = ChatClient_Mock.defaultMockedConfig
            config.isClientInActiveMode = true
            client = ChatClient_Mock(
                config: config,
                environment: Self.chatClientEnvironment()
            )
            client.addBackgroundWorker(
                MessageEditor(
                    messageRepository: client.messageRepository,
                    database: client.databaseContainer,
                    apiClient: client.apiClient
                )
            )
            client.addBackgroundWorker(
                MessageSender(
                    messageRepository: client.messageRepository,
                    eventsNotificationCenter: client.eventNotificationCenter,
                    database: client.databaseContainer,
                    apiClient: client.apiClient
                )
            )
            client.addBackgroundWorker(
                AttachmentQueueUploader(
                    database: client.databaseContainer,
                    apiClient: client.apiClient,
                    attachmentPostProcessor: nil
                )
            )
        }
        
        func chatEnvironment(usesMockedUpdaters: Bool) -> Chat.Environment {
            Chat.Environment(
                chatStateBuilder: { [unowned self] in
                    self.chatState = ChatState(channelQuery: $0, messageOrder: $1, memberSorting: $2, channelUpdater: $3, client: $4, environment: $5)
                    return self.chatState!
                },
                channelUpdaterBuilder: { [unowned self] in
                    self.channelUpdater = ChannelUpdater(
                        channelRepository: $0,
                        callRepository: $1,
                        messageRepository: $2,
                        paginationStateHandler: $3,
                        database: $4,
                        apiClient: $5
                    )
                    self.channelUpdaterMock = ChannelUpdater_Mock(
                        channelRepository: $0,
                        callRepository: $1,
                        messageRepository: $2,
                        paginationStateHandler: $3,
                        database: $4,
                        apiClient: $5
                    )
                    return usesMockedUpdaters ? self.channelUpdaterMock : self.channelUpdater
                },
                memberUpdaterBuilder: { [unowned self] in
                    self.memberUpdater = ChannelMemberUpdater(database: $0, apiClient: $1)
                    self.memberUpdaterMock = ChannelMemberUpdater_Mock(database: $0, apiClient: $1)
                    return usesMockedUpdaters ? self.memberUpdaterMock : self.memberUpdater
                },
                messageUpdaterBuilder: { [unowned self] in
                    self.messageUpdater = MessageUpdater(isLocalStorageEnabled: $0, messageRepository: $1, database: $2, apiClient: $3)
                    self.messageUpdaterMock = MessageUpdater_Mock(isLocalStorageEnabled: $0, messageRepository: $1, database: $2, apiClient: $3)
                    return usesMockedUpdaters ? self.messageUpdaterMock : self.messageUpdater
                },
                readStateSenderBuilder: { [unowned self] in
                    self.readStateSender = Chat.ReadStateSender(cid: $0, channelUpdater: $1, authenticationRepository: $2, messageRepository: $3)
                    return self.readStateSender!
                },
                typingEventsSenderBuilder: { [unowned self] in
                    self.typingEventsSender = TypingEventsSender(database: $0, apiClient: $1)
                    self.typingEventsSenderMock = TypingEventsSender_Mock(database: $0, apiClient: $1)
                    return usesMockedUpdaters ? self.typingEventsSenderMock : self.typingEventsSender
                }
            )
        }
        
        static func chatClientEnvironment() -> ChatClient.Environment {
            var environment = ChatClient.Environment.mock
            environment.messageRepositoryBuilder = MessageRepository.init
            return environment
        }
    }
}
