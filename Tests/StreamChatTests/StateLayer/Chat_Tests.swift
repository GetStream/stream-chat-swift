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
    private var expectedTestError: TestError!
    
    @MainActor override func setUpWithError() throws {
        channelId = ChannelId.unique
        env = TestEnvironment()
        expectedTestError = TestError()
        setUpChat(usesMockedChannelUpdater: true)
    }

    override func tearDownWithError() throws {
        env.cleanUp()
        channelId = nil
        chat = nil
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
        await setUpChat(usesMockedChannelUpdater: false)
        try await chat.get(watch: true)
        
        // Recreate the chat which simulates a new session and loading the state from the store
        await setUpChat(usesMockedChannelUpdater: false)
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
        await setUpChat(usesMockedChannelUpdater: false)
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
    
    // MARK: - Message Loading and State
    
    func test_restoreMessages_whenExistingMessages_thenStateUpdates() async throws {
        // DB has some older messages loaded
        let initialChannelPayload = makeChannelPayload(messageCount: 3, createdAtOffset: 0)
        try await env.client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: initialChannelPayload)
        }
        
        await setUpChat(usesMockedChannelUpdater: false, loadState: false)
        
        // Accessing the state triggers loading the inital states
        await XCTAssertEqual(initialChannelPayload.messages.map(\.id), chat.state.messages.map(\.id))
    }
    
    func test_loadMessages_whenAPIRequestSucceeds_thenStateUpdates() async throws {
        await setUpChat(usesMockedChannelUpdater: false)
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
        await setUpChat(usesMockedChannelUpdater: false)
        
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
        
        await setUpChat(usesMockedChannelUpdater: false)

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
        await setUpChat(usesMockedChannelUpdater: false)
        
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
        
        await setUpChat(usesMockedChannelUpdater: false)
 
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
    
    // MARK: - Members
    
    func test_addMembers_whenChannelUpdaterSucceeds_thenAddMembersSucceeds() async throws {
        for hideHistory in [true, false] {
            let currentUserId = String.unique
            env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
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
            let currentUserId = String.unique
            env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
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
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.channelUpdaterMock.removeMembers_completion_result = .success(())
        let memberIds: [UserId] = [.unique, .unique]
        try await chat.removeMembers(memberIds, systemMessage: "My system message")
        XCTAssertEqual(channelId, env.channelUpdaterMock.removeMembers_cid)
        XCTAssertEqual(memberIds.sorted(), env.channelUpdaterMock.removeMembers_userIds?.sorted())
        XCTAssertEqual("My system message", env.channelUpdaterMock.removeMembers_message)
        XCTAssertEqual(currentUserId, env.channelUpdaterMock.removeMembers_currentUserId)
    }
    
    func test_removeMembers_whenChannelUpdaterFails_thenRemoveMembersSucceeds() async throws {
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
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
    
    // TODO: not done
    func test_loadMembers_whenAPIRequestSucceeds_thenLoadMembersSucceeds() async throws {
        // loadMembers(with pagination: Pagination)
    }
    
    // TODO: not done
    func test_loadMembers_whenAPIRequestFails_thenLoadMembersSucceeds() async throws {
        // loadMembers(with pagination: Pagination)
    }
    
    // MARK: - Member Moderation
    
    func test_banMember_whenMemberUpdaterSucceeds_thenBanMemberSucceeds() async throws {
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.memberUpdater.banMember_completion_result = .success(())
        let reason = "Test reason"
        let timeout = 5
        let memberId: UserId = .unique
        try await chat.banMember(memberId, reason: reason, timeout: timeout)
        XCTAssertEqual(channelId, env.memberUpdater.banMember_cid)
        XCTAssertEqual(memberId, env.memberUpdater.banMember_userId)
        XCTAssertEqual(reason, env.memberUpdater.banMember_reason)
        XCTAssertEqual(timeout, env.memberUpdater.banMember_timeoutInMinutes)
        XCTAssertEqual(false, env.memberUpdater.banMember_shadow)
    }
    
    func test_banMember_whenMemberUpdaterFails_thenBanMemberSucceeds() async throws {
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.memberUpdater.banMember_completion_result = .failure(expectedTestError)
        let reason = "Test reason"
        let timeout = 5
        let memberId: UserId = .unique
        
        await XCTAssertAsyncFailure(
            try await chat.banMember(memberId, reason: reason, timeout: timeout),
            expectedTestError
        )
        
        XCTAssertEqual(channelId, env.memberUpdater.banMember_cid)
        XCTAssertEqual(memberId, env.memberUpdater.banMember_userId)
        XCTAssertEqual(reason, env.memberUpdater.banMember_reason)
        XCTAssertEqual(timeout, env.memberUpdater.banMember_timeoutInMinutes)
        XCTAssertEqual(false, env.memberUpdater.banMember_shadow)
    }
    
    func test_shadowBanMember_whenMemberUpdaterSucceeds_thenShadowBanMemberSucceeds() async throws {
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.memberUpdater.banMember_completion_result = .success(())
        let reason = "Test reason"
        let timeout = 5
        let memberId: UserId = .unique
        try await chat.shadowBanMember(memberId, reason: reason, timeout: timeout)
        XCTAssertEqual(channelId, env.memberUpdater.banMember_cid)
        XCTAssertEqual(memberId, env.memberUpdater.banMember_userId)
        XCTAssertEqual(reason, env.memberUpdater.banMember_reason)
        XCTAssertEqual(timeout, env.memberUpdater.banMember_timeoutInMinutes)
        XCTAssertEqual(true, env.memberUpdater.banMember_shadow)
    }
    
    func test_shadowBanMember_whenMemberUpdaterFails_thenShadowBanMemberSucceeds() async throws {
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.memberUpdater.banMember_completion_result = .failure(expectedTestError)
        let reason = "Test reason"
        let timeout = 5
        let memberId: UserId = .unique
        
        await XCTAssertAsyncFailure(
            try await chat.shadowBanMember(memberId, reason: reason, timeout: timeout),
            expectedTestError
        )
        
        XCTAssertEqual(channelId, env.memberUpdater.banMember_cid)
        XCTAssertEqual(memberId, env.memberUpdater.banMember_userId)
        XCTAssertEqual(reason, env.memberUpdater.banMember_reason)
        XCTAssertEqual(timeout, env.memberUpdater.banMember_timeoutInMinutes)
        XCTAssertEqual(true, env.memberUpdater.banMember_shadow)
    }
    
    func test_unbanMember_whenMemberUpdaterSucceeds_thenUnbanMemberSucceeds() async throws {
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.memberUpdater.unbanMember_completion_result = .success(())
        let memberId: UserId = .unique
        try await chat.unbanMember(memberId)
        XCTAssertEqual(channelId, env.memberUpdater.unbanMember_cid)
        XCTAssertEqual(memberId, env.memberUpdater.unbanMember_userId)
    }
    
    func test_unbanMember_whenMemberUpdaterFails_thenUnbanMemberSucceeds() async throws {
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.memberUpdater.unbanMember_completion_result = .failure(expectedTestError)
        let memberId: UserId = .unique
        await XCTAssertAsyncFailure(try await chat.unbanMember(memberId), expectedTestError)
        XCTAssertEqual(channelId, env.memberUpdater.unbanMember_cid)
        XCTAssertEqual(memberId, env.memberUpdater.unbanMember_userId)
    }
    
    // MARK: - Messages
    
    func test_deleteMessage_whenMessageUpdaterSucceeds_thenDeleteMessageSucceeds() async throws {
        for hard in [true, false] {
            let currentUserId = String.unique
            env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
            env.messageUpdater.deleteMessage_completion_result = .success(())
            let messageId: MessageId = .unique
            try await chat.deleteMessage(messageId, hard: hard)
            XCTAssertEqual(messageId, env.messageUpdater.deleteMessage_messageId)
            XCTAssertEqual(hard, env.messageUpdater.deleteMessage_hard)
        }
    }
    
    func test_deleteMessage_whenMessageUpdaterFails_thenDeleteMessageSucceeds() async throws {
        for hard in [true, false] {
            let currentUserId = String.unique
            env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
            env.messageUpdater.deleteMessage_completion_result = .failure(expectedTestError)
            let messageId: MessageId = .unique
            await XCTAssertAsyncFailure(try await chat.deleteMessage(messageId, hard: hard), expectedTestError)
            XCTAssertEqual(messageId, env.messageUpdater.deleteMessage_messageId)
            XCTAssertEqual(hard, env.messageUpdater.deleteMessage_hard)
        }
    }
    
    // TODO: fails due to backgroundWorker
    func test_resendMessage_whenAPIRequestSucceeds_thenResendMessageSucceeds() async throws {
//        let currentUserId = String.unique
//        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
//        env.messageUpdater.resendMessage_completion_result = .success(())
//        let messageId: MessageId = .unique
//        try await chat.resendMessage(messageId)
//        XCTAssertEqual(messageId, env.messageUpdater.resendMessage_messageId)
    }
    
    // TODO: fails due to backgroundWorker
    func test_resendMessage_whenAPIRequestFails_thenResendMessageSucceeds() async throws {
//        let currentUserId = String.unique
//        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
//        env.messageUpdater.resendMessage_completion_result = .failure(expectedTestError)
//        let messageId: MessageId = .unique
//        await XCTAssertAsyncFailure(try await chat.resendMessage(messageId), expectedTestError)
//        XCTAssertEqual(messageId, env.messageUpdater.resendMessage_messageId)
    }
    
    // TODO: fails due to backgroundWorker
    func test_resendAttachment_whenAPIRequestSucceeds_thenResendAttachmentSucceeds() async throws {
//        let currentUserId = String.unique
//        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
//        env.messageUpdater.restartFailedAttachmentUploading_completion_result = .success(())
//        let attachmentId: AttachmentId = .unique
//        try await chat.resendAttachment(attachmentId)
//        XCTAssertEqual(attachmentId, env.messageUpdater.restartFailedAttachmentUploading_id)
    }
    
    // TODO: fails due to backgroundWorker
    func test_resendAttachment_whenAPIRequestFails_thenResendAttachmentSucceeds() async throws {
//        let currentUserId = String.unique
//        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
//        env.messageUpdater.restartFailedAttachmentUploading_completion_result = .failure(expectedTestError)
//        let attachmentId: AttachmentId = .unique
//        await XCTAssertAsyncFailure(try await chat.resendAttachment(attachmentId), expectedTestError)
//        XCTAssertEqual(attachmentId, env.messageUpdater.restartFailedAttachmentUploading_id)
    }
    
    // TODO: fails due to backgroundWorker
    func test_sendMessage_whenAPIRequestSucceeds_thenSendMessageSucceeds() async throws {
//        let currentUserId = String.unique
//        let messageId: MessageId = .unique
//        let text: String = "Test message"
//        let createdAt: Date = .unique
//        let message: ChatMessage = .mock(
//            id: messageId,
//            cid: channelId,
//            text: text,
//            author: .mock(id: currentUserId),
//            createdAt: createdAt,
//            isSentByCurrentUser: true
//        )
//        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
//        env.channelUpdaterMock.createNewMessage_completion_result = .success(message)
//        try await chat.sendMessage(with: text, messageId: messageId)
//        XCTAssertEqual(channelId, env.channelUpdaterMock.createNewMessage_cid)
//        XCTAssertEqual(text, env.channelUpdaterMock.createNewMessage_text)
    }
    
    // TODO: fails due to backgroundWorker
    func test_sendMessage_whenAPIRequestFails_thenSendMessageSucceeds() async throws {
//        let currentUserId = String.unique
//        let messageId: MessageId = .unique
//        let text: String = "Test message"
//        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
//        env.channelUpdaterMock.createNewMessage_completion_result = .failure(expectedTestError)
//        await XCTAssertAsyncFailure(_ = try await chat.sendMessage(with: text, messageId: messageId), expectedTestError)
//        XCTAssertEqual(channelId, env.channelUpdaterMock.createNewMessage_cid)
//        XCTAssertEqual(text, env.channelUpdaterMock.createNewMessage_text)
    }
    
    // TODO: not done
    func test_updateMessage_whenAPIRequestSucceeds_thenUpdateMessageSucceeds() async throws {
        // updateMessage(_ messageId: MessageId, with text: String, attachments: [AnyAttachmentPayload] = [], extraData: [String: RawJSON]? = nil, skipEnrichURL: Bool = false)
    }
    
    // TODO: not done
    func test_updateMessage_whenAPIRequestFails_thenUpdateMessageSucceeds() async throws {
        // updateMessage(_ messageId: MessageId, with text: String, attachments: [AnyAttachmentPayload] = [], extraData: [String: RawJSON]? = nil, skipEnrichURL: Bool = false)
    }
    
    // TODO: not done
    func test_loadMessages_whenAPIRequestSucceeds_thenLoadMessagesSucceeds() async throws {
        // loadMessages(with pagination: MessagesPagination)
    }
    
    // TODO: not done
    func test_loadMessages_whenAPIRequestFails_thenLoadMessagesSucceeds() async throws {
        // loadMessages(with pagination: MessagesPagination)
    }
    
    // TODO: not done
    func test_loadMessagesFirstPage_whenAPIRequestSucceeds_thenLoadMessagesFirstPageSucceeds() async throws {
        // loadMessagesFirstPage()
    }
    
    // TODO: not done
    func test_loadMessagesFirstPage_whenAPIRequestFails_thenLoadMessagesFirstPageSucceeds() async throws {
        // loadMessagesFirstPage()
    }
    
    // TODO: not done
    func test_loadMessagesBeforeMessageId_whenAPIRequestSucceeds_thenLoadMessagesBeforeMessageIdSucceeds() async throws {
        // loadMessages(before messageId: MessageId? = nil, limit: Int? = nil)
    }
    
    // TODO: not done
    func test_loadMessagesBeforeMessageId_whenAPIRequestFails_thenLoadMessagesBeforeMessageIdSucceeds() async throws {
        // loadMessages(before messageId: MessageId? = nil, limit: Int? = nil)
    }
    
    // TODO: not done
    func test_loadMessagesAfterMessageId_whenAPIRequestSucceeds_thenLoadMessagesAfterMessageIdSucceeds() async throws {
        // loadMessages(after messageId: MessageId? = nil, limit: Int? = nil)
    }
    
    // TODO: not done
    func test_loadMessagesAfterMessageId_whenAPIRequestFails_thenLoadMessagesAfterMessageIdSucceeds() async throws {
        // loadMessages(after messageId: MessageId? = nil, limit: Int? = nil)
    }
    
    // TODO: not done
    func test_loadMessagesAroundMessageId_whenAPIRequestSucceeds_thenLoadMessagesAroundMessageIdSucceeds() async throws {
        // loadMessages(around messageId: MessageId? = nil, limit: Int? = nil)
    }
    
    // TODO: not done
    func test_loadMessagesAroundMessageId_whenAPIRequestFails_thenLoadMessagesAroundMessageIdSucceeds() async throws {
        // loadMessages(around messageId: MessageId? = nil, limit: Int? = nil)
    }
    
    // TODO: not done
    func test_sendMessageAction_whenAPIRequestSucceeds_thenSendMessageActionSucceeds() async throws {
        // sendMessageAction(in messageId: MessageId, action: AttachmentAction)
    }
    
    // TODO: not done
    func test_sendMessageAction_whenAPIRequestFails_thenSendMessageActionSucceeds() async throws {
        // sendMessageAction(in messageId: MessageId, action: AttachmentAction)
    }
    
    // MARK: - Message Flagging
    
    func test_flagMessageAction_whenMessageUpdaterSucceeds_thenFlagMessageActionSucceeds() async throws {
        let currentUserId = String.unique
        let messageId: MessageId = .unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.messageUpdater.flagMessage_completion_result = .success(())
        try await chat.flagMessage(messageId)
        XCTAssertEqual(channelId, env.messageUpdater.flagMessage_cid)
        XCTAssertEqual(messageId, env.messageUpdater.flagMessage_messageId)
        XCTAssertEqual(true, env.messageUpdater.flagMessage_flag)
    }
    
    func test_flagMessageAction_whenMessageUpdaterFails_thenFlagMessageActionSucceeds() async throws {
        let currentUserId = String.unique
        let messageId: MessageId = .unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.messageUpdater.flagMessage_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.flagMessage(messageId), expectedTestError)
        XCTAssertEqual(channelId, env.messageUpdater.flagMessage_cid)
        XCTAssertEqual(messageId, env.messageUpdater.flagMessage_messageId)
        XCTAssertEqual(true, env.messageUpdater.flagMessage_flag)
    }
    
    func test_unflagMessageAction_whenMessageUpdaterSucceeds_thenUnflagMessageActionSucceeds() async throws {
        let currentUserId = String.unique
        let messageId: MessageId = .unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.messageUpdater.flagMessage_completion_result = .success(())
        try await chat.unflagMessage(messageId)
        XCTAssertEqual(channelId, env.messageUpdater.flagMessage_cid)
        XCTAssertEqual(messageId, env.messageUpdater.flagMessage_messageId)
        XCTAssertEqual(false, env.messageUpdater.flagMessage_flag)
    }
    
    func test_unflagMessageAction_whenMessageUpdaterFails_thenUnflagMessageActionSucceeds() async throws {
        let currentUserId = String.unique
        let messageId: MessageId = .unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.messageUpdater.flagMessage_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.unflagMessage(messageId), expectedTestError)
        XCTAssertEqual(channelId, env.messageUpdater.flagMessage_cid)
        XCTAssertEqual(messageId, env.messageUpdater.flagMessage_messageId)
        XCTAssertEqual(false, env.messageUpdater.flagMessage_flag)
    }
    
    // MARK: - Message Rich Content
    
    func test_enrichURLAction_whenChannelUpdaterSucceeds_thenEnrichURLActionSucceeds() async throws {
        let currentUserId = String.unique
        let url: URL = .unique()
        let expectedLinkAttachmentPayload = LinkAttachmentPayload(
            originalURL: url,
            title: "Chat API Documentation",
            text: "Stream, scalable news feeds and activity streams as a service.",
            author: "Stream",
            previewURL: TestImages.r2.url
        )
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.channelUpdaterMock.enrichUrl_completion_result = .success(expectedLinkAttachmentPayload)
        let actualLinkAttachmentPayload = try await chat.enrichURL(url)
        XCTAssertEqual(url, env.channelUpdaterMock.enrichUrl_url)
        XCTAssertEqual(actualLinkAttachmentPayload, expectedLinkAttachmentPayload)
    }
    
    func test_enrichURLAction_whenChannelUpdaterFails_thenEnrichURLActionSucceeds() async throws {
        let currentUserId = String.unique
        let url: URL = .unique()
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.channelUpdaterMock.enrichUrl_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(_ = try await chat.enrichURL(url), expectedTestError)
        XCTAssertEqual(url, env.channelUpdaterMock.enrichUrl_url)
    }
    
    // MARK: - Message Pinning
    
    // TODO: fails due to backgroundWorker
    func test_pinMessageAction_whenAPIRequestSucceeds_thenPinMessageActionSucceeds() async throws {
//        let currentUserId = String.unique
//        let messageId: MessageId = .unique
//        let pinning = MessagePinning(expirationDate: .unique)
//        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
//        env.messageUpdater.pinMessage_completion_result = .success(())
//        try await chat.pinMessage(messageId, pinning: pinning)
//        XCTAssertEqual(messageId, env.messageUpdater.pinMessage_messageId)
//        XCTAssertEqual(pinning, env.messageUpdater.pinMessage_pinning)
    }
    
    // TODO: fails due to backgroundWorker
    func test_pinMessageAction_whenAPIRequestFails_thenPinMessageActionSucceeds() async throws {
//        let currentUserId = String.unique
//        let messageId: MessageId = .unique
//        let pinning = MessagePinning(expirationDate: .unique)
//        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
//        env.messageUpdater.pinMessage_completion_result = .failure(expectedTestError)
//        await XCTAssertAsyncFailure(try await chat.pinMessage(messageId, pinning: pinning), expectedTestError)
//        XCTAssertEqual(messageId, env.messageUpdater.pinMessage_messageId)
//        XCTAssertEqual(pinning, env.messageUpdater.pinMessage_pinning)
    }
    
    // TODO: fails due to backgroundWorker
    func test_unpinMessageAction_whenAPIRequestSucceeds_thenUnpinMessageActionSucceeds() async throws {
//        let currentUserId = String.unique
//        let messageId: MessageId = .unique
//        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
//        env.messageUpdater.unpinMessage_completion_result = .success(())
//        try await chat.unpinMessage(messageId)
//        XCTAssertEqual(messageId, env.messageUpdater.pinMessage_messageId)
    }
    
    // TODO: fails due to backgroundWorker
    func test_unpinMessageAction_whenAPIRequestFails_thenUnpinMessageActionSucceeds() async throws {
//        let currentUserId = String.unique
//        let messageId: MessageId = .unique
//        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
//        env.messageUpdater.unpinMessage_completion_result = .failure(expectedTestError)
//        await XCTAssertAsyncFailure(try await chat.unpinMessage(messageId), expectedTestError)
//        XCTAssertEqual(messageId, env.messageUpdater.pinMessage_messageId)
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
        let currentUserId = String.unique
        let messageId: MessageId = .unique
        let reactionType: MessageReactionType = .init(rawValue: "like")
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.messageUpdater.deleteReaction_completion_result = .success(())
        try await chat.deleteReaction(from: messageId, with: .init(rawValue: "like"))
        XCTAssertEqual(messageId, env.messageUpdater.deleteReaction_messageId)
        XCTAssertEqual(reactionType, env.messageUpdater.deleteReaction_type)
    }
    
    func test_deleteReactionAction_whenMessageUpdaterFails_thenDeleteReactionActionSucceeds() async throws {
        let currentUserId = String.unique
        let messageId: MessageId = .unique
        let reactionType: MessageReactionType = .init(rawValue: "like")
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.messageUpdater.deleteReaction_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(
            try await chat.deleteReaction(from: messageId, with: .init(rawValue: "like")),
            expectedTestError
        )
        XCTAssertEqual(messageId, env.messageUpdater.deleteReaction_messageId)
        XCTAssertEqual(reactionType, env.messageUpdater.deleteReaction_type)
    }
    
    // TODO: not done
    func test_sendReactionAction_whenAPIRequestSucceeds_thenSendReactionActionSucceeds() async throws {
//        sendReaction(to messageId: MessageId, with type: MessageReactionType, score: Int = 1, enforceUnique: Bool = false, extraData: [String: RawJSON] = [:])
    }
    
    // TODO: not done
    func test_sendReactionAction_whenAPIRequestFails_thenSendReactionActionSucceeds() async throws {
//        sendReaction(to messageId: MessageId, with type: MessageReactionType, score: Int = 1, enforceUnique: Bool = false, extraData: [String: RawJSON] = [:])
    }
    
    // TODO: not done
    func test_loadReactionsAction_whenAPIRequestSucceeds_thenLoadReactionsActionSucceeds() async throws {
        // loadReactions(of messageId: MessageId, pagination: Pagination)
    }
    
    // TODO: not done
    func test_loadReactionsAction_whenAPIRequestFails_thenLoadReactionsActionSucceeds() async throws {
        // loadReactions(of messageId: MessageId, pagination: Pagination)
    }
    
    // TODO: not done
    func test_loadNextReactionsAction_whenAPIRequestSucceeds_thenLoadNextReactionsActionSucceeds() async throws {
        // loadNextReactions(of messageId: MessageId, limit: Int? = nil)
    }
    
    // TODO: not done
    func test_loadNextReactionsAction_whenAPIRequestFails_thenLoadNextReactionsActionSucceeds() async throws {
        // loadNextReactions(of messageId: MessageId, limit: Int? = nil)
    }
    
    // MARK: - Message Reading
    
    // TODO: ChannelDoesNotExist
    func test_markReadAction_whenAPIRequestSucceeds_thenMarkReadActionSucceeds() async throws {
//        let currentUserId = String.unique
//        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
//        env.channelUpdaterMock.markRead_completion_result = .success(())
//        try await chat.markRead()
//        XCTAssertEqual(channelId, env.channelUpdaterMock.markRead_cid)
//        XCTAssertEqual(currentUserId, env.channelUpdaterMock.markRead_userId)
    }
    
    // TODO: ChannelDoesNotExist
    func test_markReadAction_whenAPIRequestFails_thenMarkReadActionSucceeds() async throws {
//        let currentUserId = String.unique
//        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
//        env.channelUpdaterMock.markRead_completion_result = .failure(expectedTestError)
//        await XCTAssertAsyncFailure(try await chat.markRead(), expectedTestError)
//        XCTAssertEqual(channelId, env.channelUpdaterMock.markRead_cid)
//        XCTAssertEqual(currentUserId, env.channelUpdaterMock.markRead_userId)
    }
    
    // TODO: ChannelDoesNotExist and lastReadMessageId assertion
    func test_markUnreadAction_whenAPIRequestSucceeds_thenMarkUnreadActionSucceeds() async throws {
//        let currentUserId = String.unique
//        let messageId: MessageId = .unique
//        let channel: ChatChannel = .mock(cid: channelId, name: .unique, imageURL: .unique(), extraData: [:])
//        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
//        env.channelUpdaterMock.markUnread_completion_result = .success(channel)
//        try await chat.markUnread(from: messageId)
//        XCTAssertEqual(channelId, env.channelUpdaterMock.markUnread_cid)
//        XCTAssertEqual(currentUserId, env.channelUpdaterMock.markUnread_userId)
//        XCTAssertEqual(messageId, env.channelUpdaterMock.markUnread_messageId)
//        XCTAssertEqual(messageId, env.channelUpdaterMock.markUnread_lastReadMessageId) // TODO: not done
    }
    
    // TODO: ChannelDoesNotExist and lastReadMessageId assertion
    func test_markUnreadAction_whenAPIRequestFails_thenMarkUnreadActionSucceeds() async throws {
//        let currentUserId = String.unique
//        let messageId: MessageId = .unique
//        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
//        env.channelUpdaterMock.markUnread_completion_result = .failure(expectedTestError)
//        await XCTAssertAsyncFailure(try await chat.markUnread(from: messageId), expectedTestError)
//        XCTAssertEqual(channelId, env.channelUpdaterMock.markUnread_cid)
//        XCTAssertEqual(currentUserId, env.channelUpdaterMock.markUnread_userId)
//        XCTAssertEqual(messageId, env.channelUpdaterMock.markUnread_messageId)
//        XCTAssertEqual(messageId, env.channelUpdaterMock.markUnread_lastReadMessageId) // TODO: not done
    }
    
    // MARK: - Message Replies
    
    // TODO: not done
    func test_replyAction_whenAPIRequestSucceeds_thenReplyActionSucceeds() async throws {
//        reply(
//            to parentMessageId: MessageId,
//            text: String,
//            showReplyInChannel: Bool = false,
//            attachments: [AnyAttachmentPayload] = [],
//            quote quotedMessageId: MessageId? = nil,
//            mentions: [UserId] = [],
//            pinning: MessagePinning? = nil,
//            extraData: [String: RawJSON] = [:],
//            silent: Bool = false,
//            skipPushNotification: Bool = false,
//            skipEnrichURL: Bool = false,
//            messageId: MessageId? = nil
//        )
    }
    
    // TODO: not done
    func test_replyAction_whenAPIRequestFails_thenReplyActionSucceeds() async throws {
//        reply(
//            to parentMessageId: MessageId,
//            text: String,
//            showReplyInChannel: Bool = false,
//            attachments: [AnyAttachmentPayload] = [],
//            quote quotedMessageId: MessageId? = nil,
//            mentions: [UserId] = [],
//            pinning: MessagePinning? = nil,
//            extraData: [String: RawJSON] = [:],
//            silent: Bool = false,
//            skipPushNotification: Bool = false,
//            skipEnrichURL: Bool = false,
//            messageId: MessageId? = nil
//        )
    }
    
    // TODO: not done
    func test_loadRepliesAction_whenAPIRequestSucceeds_thenLoadRepliesActionSucceeds() async throws {
        // loadReplies(of messageId: MessageId, pagination: MessagesPagination)
    }
    
    // TODO: not done
    func test_loadRepliesAction_whenAPIRequestFails_thenLoadRepliesActionSucceeds() async throws {
        // loadReplies(of messageId: MessageId, pagination: MessagesPagination)
    }
    
    // TODO: not done
    func test_loadRepliesFirstPageAction_whenAPIRequestSucceeds_thenLoadRepliesFirstPageActionSucceeds() async throws {
        // loadRepliesFirstPage(of messageId: MessageId, limit: Int? = nil)
    }
    
    // TODO: not done
    func test_loadRepliesFirstPageAction_whenAPIRequestFails_thenLoadRepliesFirstPageActionSucceeds() async throws {
        // loadRepliesFirstPage(of messageId: MessageId, limit: Int? = nil)
    }
    
    // TODO: not done
    func test_loadRepliesBeforeAction_whenAPIRequestSucceeds_thenLoadRepliesBeforeActionSucceeds() async throws {
        // loadReplies(before replyId: MessageId? = nil, of messageId: MessageId, limit: Int? = nil)
    }
    
    // TODO: not done
    func test_loadRepliesBeforeAction_whenAPIRequestFails_thenLoadRepliesBeforeActionSucceeds() async throws {
        // loadReplies(before replyId: MessageId? = nil, of messageId: MessageId, limit: Int? = nil)
    }
    
    // TODO: not done
    func test_loadRepliesAfterAction_whenAPIRequestSucceeds_thenLoadRepliesAfterActionSucceeds() async throws {
        // loadReplies(after replyId: MessageId? = nil, of messageId: MessageId, limit: Int? = nil)
    }
    
    // TODO: not done
    func test_loadRepliesAfterAction_whenAPIRequestFails_thenLoadRepliesAfterActionSucceeds() async throws {
        // loadReplies(after replyId: MessageId? = nil, of messageId: MessageId, limit: Int? = nil)
    }
    
    // TODO: not done
    func test_loadRepliesAroundAction_whenAPIRequestSucceeds_thenLoadRepliesAroundActionSucceeds() async throws {
        // loadReplies(around replyId: MessageId, of messageId: MessageId, limit: Int? = nil)
    }
    
    // TODO: not done
    func test_loadRepliesAroundAction_whenAPIRequestFails_thenLoadRepliesAroundActionSucceeds() async throws {
        // loadReplies(around replyId: MessageId, of messageId: MessageId, limit: Int? = nil)
    }
    
    // MARK: - Message State Observing
    
    // TODO: not done
    func test_makeMessageStateAction_whenAPIRequestSucceeds_thenMakeMessageStateActionSucceeds() async throws {
        // makeMessageState(for messageId: MessageId)
    }
    
    // TODO: not done
    func test_makeMessageStateAction_whenAPIRequestFails_thenMakeMessageStateActionSucceeds() async throws {
        // makeMessageState(for messageId: MessageId)
    }
    
    // MARK: - Message Translations
    
    func test_translateMessageStateAction_whenMessageUpdaterSucceeds_thenTranslateMessageActionSucceeds() async throws {
        let currentUserId = String.unique
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
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.messageUpdater.translate_completion_result = .success(message)
        try await chat.translateMessage(messageId, to: language)
        XCTAssertEqual(messageId, env.messageUpdater.translate_messageId)
        XCTAssertEqual(language, env.messageUpdater.translate_language)
    }
    
    func test_translateMessageStateAction_whenMessageUpdaterFails_thenTranslateMessageActionSucceeds() async throws {
        let currentUserId = String.unique
        let messageId: MessageId = .unique
        let _: String = "Test message"
        let _: Date = .unique
        let language: TranslationLanguage = .turkish
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.messageUpdater.translate_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(
            _ = try await chat.translateMessage(messageId, to: language),
            expectedTestError
        )
        XCTAssertEqual(messageId, env.messageUpdater.translate_messageId)
        XCTAssertEqual(language, env.messageUpdater.translate_language)
    }
    
    // MARK: - Muting or Hiding the Channel
    
    func test_muteAction_whenChannelUpdaterSucceeds_thenMuteActionSucceeds() async throws {
        for expiration in [nil, 10] {
            let currentUserId = String.unique
            env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
            env.channelUpdaterMock.muteChannel_completion_result = .success(())
            try await chat.mute(expiration: expiration)
            XCTAssertEqual(channelId, env.channelUpdaterMock.muteChannel_cid)
            XCTAssertEqual(expiration, env.channelUpdaterMock.muteChannel_expiration)
            XCTAssertEqual(true, env.channelUpdaterMock.muteChannel_mute)
        }
    }
    
    func test_muteAction_whenChannelUpdaterFails_thenMuteActionSucceeds() async throws {
        for expiration in [nil, 10] {
            let currentUserId = String.unique
            env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
            env.channelUpdaterMock.muteChannel_completion_result = .failure(expectedTestError)
            await XCTAssertAsyncFailure(try await chat.mute(expiration: expiration), expectedTestError)
            XCTAssertEqual(channelId, env.channelUpdaterMock.muteChannel_cid)
            XCTAssertEqual(expiration, env.channelUpdaterMock.muteChannel_expiration)
            XCTAssertEqual(true, env.channelUpdaterMock.muteChannel_mute)
        }
    }
    
    func test_hideAction_whenChannelUpdaterSucceeds_thenHideActionSucceeds() async throws {
        for clearHistory in [true, false] {
            let currentUserId = String.unique
            env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
            env.channelUpdaterMock.hideChannel_completion_result = .success(())
            try await chat.hide(clearHistory: clearHistory)
            XCTAssertEqual(channelId, env.channelUpdaterMock.hideChannel_cid)
            XCTAssertEqual(clearHistory, env.channelUpdaterMock.hideChannel_clearHistory)
        }
    }
    
    func test_hideAction_whenChannelUpdaterFails_thenHideActionSucceeds() async throws {
        for clearHistory in [true, false] {
            let currentUserId = String.unique
            env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
            env.channelUpdaterMock.hideChannel_completion_result = .failure(expectedTestError)
            await XCTAssertAsyncFailure(try await chat.hide(clearHistory: clearHistory), expectedTestError)
            XCTAssertEqual(channelId, env.channelUpdaterMock.hideChannel_cid)
            XCTAssertEqual(clearHistory, env.channelUpdaterMock.hideChannel_clearHistory)
        }
    }
    
    func test_showAction_whenChannelUpdaterSucceeds_thenShowActionSucceeds() async throws {
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.channelUpdaterMock.showChannel_completion_result = .success(())
        try await chat.show()
        XCTAssertEqual(channelId, env.channelUpdaterMock.showChannel_cid)
    }
    
    func test_hideAction_whenChannelUpdaterFails_thenShowActionSucceeds() async throws {
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.channelUpdaterMock.showChannel_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.show(), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.showChannel_cid)
    }
    
    // MARK: - Throttling and Slow Mode
    
    func test_enableSlowModeAction_whenChannelUpdaterSucceeds_thenEnableSlowModeActionSucceeds() async throws {
        let currentUserId = String.unique
        let cooldownDuration = 10
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.channelUpdaterMock.enableSlowMode_completion_result = .success(())
        try await chat.enableSlowMode(cooldownDuration: cooldownDuration)
        XCTAssertEqual(channelId, env.channelUpdaterMock.enableSlowMode_cid)
        XCTAssertEqual(cooldownDuration, env.channelUpdaterMock.enableSlowMode_cooldownDuration)
    }
    
    func test_enableSlowModeAction_whenChannelUpdaterFails_thenEnableSlowModeActionSucceeds() async throws {
        let currentUserId = String.unique
        let cooldownDuration = 10
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.channelUpdaterMock.enableSlowMode_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.enableSlowMode(cooldownDuration: cooldownDuration), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.enableSlowMode_cid)
        XCTAssertEqual(cooldownDuration, env.channelUpdaterMock.enableSlowMode_cooldownDuration)
    }
    
    func test_disableSlowModeAction_whenChannelUpdaterSucceeds_thenDisableSlowModeActionSucceeds() async throws {
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.channelUpdaterMock.enableSlowMode_completion_result = .success(())
        try await chat.disableSlowMode()
        XCTAssertEqual(channelId, env.channelUpdaterMock.enableSlowMode_cid)
        XCTAssertEqual(0, env.channelUpdaterMock.enableSlowMode_cooldownDuration)
    }
    
    func test_disableSlowModeAction_whenChannelUpdaterFails_thenDisableSlowModeActionSucceeds() async throws {
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.channelUpdaterMock.enableSlowMode_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.disableSlowMode(), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.enableSlowMode_cid)
        XCTAssertEqual(0, env.channelUpdaterMock.enableSlowMode_cooldownDuration)
    }
    
    // MARK: - Truncating the Channel
    
    func test_truncateAction_whenChannelUpdaterSucceeds_thenTruncateActionSucceeds() async throws {
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
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
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
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
    
    // MARK: - Typing Indicator
    
    // TODO: not done
    func test_keystrokeAction_whenAPIRequestSucceeds_thenKeystrokeActionSucceeds() async throws {
        // keystroke(parentMessageId: MessageId? = nil)
    }
    
    // TODO: not done
    func test_keystrokeAction_whenAPIRequestFails_thenKeystrokeActionSucceeds() async throws {
        // keystroke(parentMessageId: MessageId? = nil)
    }
    
    // TODO: not done
    func test_stopTypingAction_whenAPIRequestSucceeds_thenStopTypingActionSucceeds() async throws {
        // stopTyping(parentMessageId: MessageId? = nil)
    }
    
    // TODO: not done
    func test_stopTypingAction_whenAPIRequestFails_thenStopTypingActionSucceeds() async throws {
        // stopTyping(parentMessageId: MessageId? = nil)
    }
    
    // MARK: - Updating the Channel
    
    // TODO: not done
    func test_updateAction_whenAPIRequestSucceeds_thenUpdateActionSucceeds() async throws {
//        update(
//            name: String?,
//            imageURL: URL?,
//            team: String?,
//            members: Set<UserId> = [],
//            invites: Set<UserId> = [],
//            extraData: [String: RawJSON] = [:]
//        )
    }
    
    // TODO: not done
    func test_updateAction_whenAPIRequestFails_thenUpdateActionSucceeds() async throws {
//        update(
//            name: String?,
//            imageURL: URL?,
//            team: String?,
//            members: Set<UserId> = [],
//            invites: Set<UserId> = [],
//            extraData: [String: RawJSON] = [:]
//        )
    }
    
    // TODO: not done
    func test_updatePartialAction_whenAPIRequestSucceeds_thenUpdatePartialActionSucceeds() async throws {
//         updatePartial(
//            name: String? = nil,
//            imageURL: URL? = nil,
//            team: String? = nil,
//            members: [UserId] = [],
//            invites: [UserId] = [],
//            extraData: [String: RawJSON] = [:],
//            unsetProperties: [String] = []
//        )
    }
    
    // TODO: not done
    func test_updatePartialAction_whenAPIRequestFails_thenUpdatePartialActionSucceeds() async throws {
//         updatePartial(
//            name: String? = nil,
//            imageURL: URL? = nil,
//            team: String? = nil,
//            members: [UserId] = [],
//            invites: [UserId] = [],
//            extraData: [String: RawJSON] = [:],
//            unsetProperties: [String] = []
//        )
    }
    
    // MARK: - Uploading and Deleting Files
    
    // TODO: not done
    func test_deleteFileAction_whenAPIRequestSucceeds_thenDeleteFileActionSucceeds() async throws {
        // deleteFile(at url: URL)
    }
    
    // TODO: not done
    func test_deleteFileAction_whenAPIRequestFails_thenDeleteFileActionSucceeds() async throws {
        // deleteFile(at url: URL)
    }
    
    // TODO: not done
    func test_deleteImageAction_whenAPIRequestSucceeds_thenDeleteImageActionSucceeds() async throws {
        // deleteImage(at url: URL)
    }
    
    // TODO: not done
    func test_deleteImageAction_whenAPIRequestFails_thenDeleteImageActionSucceeds() async throws {
        // deleteImage(at url: URL)
    }
    
    // TODO: not done
    func test_uploadAttachmentAction_whenAPIRequestSucceeds_thenUploadAttachmentActionSucceeds() async throws {
        // uploadAttachment(with localFileURL: URL, type: AttachmentType, progress: ((Double) -> Void)? = nil)
    }
    
    // TODO: not done
    func test_uploadAttachmentAction_whenAPIRequestFails_thenUploadAttachmentActionSucceeds() async throws {
        // uploadAttachment(with localFileURL: URL, type: AttachmentType, progress: ((Double) -> Void)? = nil)
    }
    
    // MARK: - Watching the Channel
    
    func test_startWatchingAction_whenChannelUpdaterSucceeds_thenStartWatchingActionSucceeds() async throws {
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.channelUpdaterMock.startWatching_completion_result = .success(())
        try await chat.watch()
        XCTAssertEqual(channelId, env.channelUpdaterMock.startWatching_cid)
    }
    
    func test_startWatchingAction_whenChannelUpdaterFails_thenStartWatchingActionSucceeds() async throws {
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.channelUpdaterMock.startWatching_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.watch(), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.startWatching_cid)
    }
    
    func test_stopWatchingAction_whenChannelUpdaterSucceeds_thenStopWatchingActionSucceeds() async throws {
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.channelUpdaterMock.stopWatching_completion_result = .success(())
        try await chat.stopWatching()
        XCTAssertEqual(channelId, env.channelUpdaterMock.stopWatching_cid)
    }
    
    func test_stopWatchingAction_whenChannelUpdaterFails_thenStopWatchingActionSucceeds() async throws {
        let currentUserId = String.unique
        env.client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        env.channelUpdaterMock.stopWatching_completion_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.stopWatching(), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdaterMock.stopWatching_cid)
    }
    
    // TODO: not done
    func test_subscribeAction_whenAPIRequestSucceeds_thenSubscribeActionSucceeds() async throws {
        // subscribe(_ handler: @escaping (Event) -> Void)
    }
    
    // TODO: not done
    func test_subscribeAction_whenAPIRequestFails_thenSubscribeActionSucceeds() async throws {
        // subscribe(_ handler: @escaping (Event) -> Void)
    }
    
    // TODO: not done
    func test_subscribeToEventAction_whenAPIRequestSucceeds_thenSubscribeToEventActionSucceeds() async throws {
        // subscribe<E>(toEvent event: E.Type, handler: @escaping (E) -> Void)
    }
    
    // TODO: not done
    func test_subscribeToEventAction_whenAPIRequestFails_thenSubscribeToEventActionSucceeds() async throws {
        // subscribe<E>(toEvent event: E.Type, handler: @escaping (E) -> Void)
    }
    
    // TODO: not done
    func test_sendEventAction_whenAPIRequestSucceeds_thenSendEventActionSucceeds() async throws {
        // sendEvent<EventPayload>(_ payload: EventPayload)
    }
    
    // TODO: not done
    func test_sendEventAction_whenAPIRequestFails_thenSendEventActionSucceeds() async throws {
        // sendEvent<EventPayload>(_ payload: EventPayload)
    }
    
    // TODO: not done
    func test_loadWatchersAction_whenAPIRequestSucceeds_thenLoadWatchersActionSucceeds() async throws {
        // loadWatchers(with pagination: Pagination)
    }
    
    // TODO: not done
    func test_loadWatchersAction_whenAPIRequestFails_thenLoadWatchersActionSucceeds() async throws {
        // loadWatchers(with pagination: Pagination)
    }
    
    // TODO: not done
    func test_loadMoreWatchersAction_whenAPIRequestSucceeds_thenLoadNextWatchersActionSucceeds() async throws {
        // loadNextWatchers(limit: Int? = nil)
    }
    
    // TODO: not done
    func test_loadMoreWatchersAction_whenAPIRequestFails_thenLoadNextWatchersActionSucceeds() async throws {
        // loadNextWatchers(limit: Int? = nil)
    }
    
    // MARK: - Test Data
    
    /// Configures chat for testing.
    ///
    /// - Parameter usesMockedChannelUpdater: Set it for false for tests which need to update the local DB and simulate API requests.
    @MainActor private func setUpChat(usesMockedChannelUpdater: Bool, loadState: Bool = true) {
        chat = Chat(
            channelQuery: ChannelQuery(cid: channelId),
            messageOrdering: .bottomToTop,
            memberSorting: [Sorting(key: .createdAt, isAscending: true)],
            client: env.client,
            environment: env.chatEnvironment(usesMockedUpdater: usesMockedChannelUpdater)
        )
        if loadState {
            _ = chat.state
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
        private(set) var memberUpdater: ChannelMemberUpdater_Mock!
        private(set) var messageUpdater: MessageUpdater_Mock!
        private(set) var readStateSender: Chat.ReadStateSender!
        private(set) var typingEventsSender: TypingEventsSender_Mock!
        
        func cleanUp() {
            client.cleanUp()
            channelUpdaterMock?.cleanUp()
            memberUpdater?.cleanUp()
            messageUpdater?.cleanUp()
            typingEventsSender?.cleanUp()
        }
        
        init() {
            client = ChatClient_Mock(
                config: ChatClient_Mock.defaultMockedConfig
            )
        }
        
        func chatEnvironment(usesMockedUpdater: Bool) -> Chat.Environment {
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
                    return usesMockedUpdater ? self.channelUpdaterMock : self.channelUpdater
                },
                memberUpdaterBuilder: { [unowned self] in
                    self.memberUpdater = ChannelMemberUpdater_Mock(database: $0, apiClient: $1)
                    return self.memberUpdater!
                },
                messageUpdaterBuilder: { [unowned self] in
                    self.messageUpdater = MessageUpdater_Mock(isLocalStorageEnabled: $0, messageRepository: $1, database: $2, apiClient: $3)
                    return self.messageUpdater!
                },
                readStateSenderBuilder: { [unowned self] in
                    self.readStateSender = Chat.ReadStateSender(cid: $0, channelUpdater: $1, authenticationRepository: $2, messageRepository: $3)
                    return self.readStateSender!
                },
                typingEventsSenderBuilder: { [unowned self] in
                    self.typingEventsSender = TypingEventsSender_Mock(database: $0, apiClient: $1)
                    return self.typingEventsSender!
                }
            )
        }
    }
}
