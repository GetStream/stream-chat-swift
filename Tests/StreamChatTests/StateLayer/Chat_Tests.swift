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
    
    override func setUpWithError() throws {
        channelId = ChannelId.unique
        env = TestEnvironment()
        expectedTestError = TestError()
        setUpChat(usesMockedChannelUpdater: true)
    }

    override func tearDownWithError() throws {
        env.cleanUp()
        channelId = nil
        chat = nil
        expectedTestError = nil
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
    
    func test_loadMessages_whenAPIRequestSucceeds_thenStateUpdates() async throws {
        setUpChat(usesMockedChannelUpdater: false)
        let pageSize = 2
        let channelPayload = makeChannelPayload(messageCount: pageSize, createdAtOffset: 0)
        env.client.mockAPIClient.test_mockResponseResult(.success(channelPayload))
        
        let result = try await chat.loadMessages(with: MessagesPagination(pageSize: pageSize))
        XCTAssertEqual(channelPayload.messages.map(\.id), result.map(\.id))
        XCTAssertEqual(channelPayload.messages.map(\.id), chat.state.messages.map(\.id))
        XCTAssertEqual(false, chat.state.hasLoadedAllPreviousMessages)
        // TODO: Should it be false?
        XCTAssertEqual(true, chat.state.hasLoadedAllNextMessages, "Although it sounds like it should be false since we got the requested amount of messages and there can be more")
        XCTAssertEqual(false, chat.state.isJumpingToMessage)
        XCTAssertEqual(false, chat.state.isLoadingPreviousMessages)
        XCTAssertEqual(false, chat.state.isLoadingMiddleMessages)
        XCTAssertEqual(false, chat.state.isLoadingNextMessages)
    }
    
    func test_loadMessagesFirstPage_whenAPIRequestSucceeds_thenStateIsReset() async throws {
        setUpChat(usesMockedChannelUpdater: false)
        
        // DB has some older messages loaded
        try await env.client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: self.makeChannelPayload(messageCount: 5, createdAtOffset: 0))
        }
        
        // Load the first page which should reset the state
        let channelPayload = makeChannelPayload(messageCount: 3, createdAtOffset: 5)
        env.client.mockAPIClient.test_mockResponseResult(.success(channelPayload))
        try await chat.loadMessagesFirstPage()
        
        XCTAssertEqual(channelPayload.messages.map(\.id), chat.state.messages.map(\.id))
        XCTAssertEqual(true, chat.state.hasLoadedAllPreviousMessages)
        XCTAssertEqual(true, chat.state.hasLoadedAllNextMessages)
        XCTAssertEqual(false, chat.state.isJumpingToMessage)
        XCTAssertEqual(false, chat.state.isLoadingPreviousMessages)
        XCTAssertEqual(false, chat.state.isLoadingMiddleMessages)
        XCTAssertEqual(false, chat.state.isLoadingNextMessages)
    }
    
    func test_loadPreviousMessages_whenAPIRequestSucceeds_thenStateUpdates() async throws {
        // DB has some messages loaded
        let initialChannelPayload = makeChannelPayload(messageCount: 5, createdAtOffset: 5)
        try await env.client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: initialChannelPayload)
        }
        
        setUpChat(usesMockedChannelUpdater: false)

        // Load older
        let channelPayload = makeChannelPayload(messageCount: 5, createdAtOffset: 0)
        env.client.mockAPIClient.test_mockResponseResult(.success(channelPayload))
        try await chat.loadPreviousMessages()
        
        let expectedIds = (channelPayload.messages + initialChannelPayload.messages).map(\.id)
        XCTAssertEqual(expectedIds, chat.state.messages.map(\.id))
        XCTAssertEqual(true, chat.state.hasLoadedAllPreviousMessages)
        XCTAssertEqual(true, chat.state.hasLoadedAllNextMessages)
        XCTAssertEqual(false, chat.state.isJumpingToMessage)
        XCTAssertEqual(false, chat.state.isLoadingPreviousMessages)
        XCTAssertEqual(false, chat.state.isLoadingMiddleMessages)
        XCTAssertEqual(false, chat.state.isLoadingNextMessages)
    }
    
    func test_loadNextMessages_whenAPIRequestSucceeds_thenStateUpdates() async throws {
        setUpChat(usesMockedChannelUpdater: false)
        
        // Reset has loaded state since we always load newest messages
        let initialChannelPayload = makeChannelPayload(messageCount: 3, createdAtOffset: 0)
        env.client.mockAPIClient.test_mockResponseResult(.success(initialChannelPayload))
        try await chat.loadMessages(around: initialChannelPayload.messages[1].id, limit: 2)
        
        // Load newer
        let channelPayload = makeChannelPayload(messageCount: 3, createdAtOffset: 5)
        env.client.mockAPIClient.test_mockResponseResult(.success(channelPayload))
        try await chat.loadNextMessages()
        
        let expectedIds = (initialChannelPayload.messages + channelPayload.messages).map(\.id)
        XCTAssertEqual(expectedIds, chat.state.messages.map(\.id))
        XCTAssertEqual(false, chat.state.hasLoadedAllPreviousMessages)
        XCTAssertEqual(true, chat.state.hasLoadedAllNextMessages)
        XCTAssertEqual(false, chat.state.isJumpingToMessage)
        XCTAssertEqual(false, chat.state.isLoadingPreviousMessages)
        XCTAssertEqual(false, chat.state.isLoadingMiddleMessages)
        XCTAssertEqual(false, chat.state.isLoadingNextMessages)
    }
    
    func test_loadMessagesAround_whenAPIRequestSucceeds_thenStateUpdates() async throws {
        // DB has some older messages loaded
        let initialChannelPayload = makeChannelPayload(messageCount: 5, createdAtOffset: 0)
        try await env.client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: initialChannelPayload)
        }
        
        setUpChat(usesMockedChannelUpdater: false)
 
        // Jump to a message
        let channelPayload = makeChannelPayload(messageCount: 3, createdAtOffset: 10)
        env.client.mockAPIClient.test_mockResponseResult(.success(channelPayload))
        try await chat.loadMessages(around: channelPayload.messages[1].id, limit: 2)
        
        XCTAssertEqual(channelPayload.messages.map(\.id), chat.state.messages.map(\.id))
        XCTAssertEqual(false, chat.state.hasLoadedAllPreviousMessages)
        XCTAssertEqual(false, chat.state.hasLoadedAllNextMessages)
        XCTAssertEqual(true, chat.state.isJumpingToMessage)
        XCTAssertEqual(false, chat.state.isLoadingPreviousMessages)
        XCTAssertEqual(false, chat.state.isLoadingMiddleMessages)
        XCTAssertEqual(false, chat.state.isLoadingNextMessages)
    }
    
    // MARK: -
    
    /// Configures chat for testing.
    ///
    /// - Parameter usesMockedChannelUpdater: Set it for false for tests which need to update the local DB and simulate API requests.
    private func setUpChat(usesMockedChannelUpdater: Bool) {
        chat = Chat(
            cid: channelId,
            channelQuery: ChannelQuery(cid: channelId),
            channelListQuery: nil,
            messageOrdering: .bottomToTop,
            memberSorting: [Sorting(key: .createdAt)],
            channelUpdater: usesMockedChannelUpdater ? env.channelUpdaterMock : env.channelUpdater,
            client: env.client,
            environment: env.chatEnvironment
        )
    }
    
    private func makeChannelPayload(messageCount: Int, createdAtOffset: Int) -> ChannelPayload {
        // Note that message pagination relies on createdAt and cid
        let messages: [MessagePayload] = (0..<messageCount)
            .map {
                .dummy(
                    messageId: "\($0 + createdAtOffset)",
                    createdAt: Date(timeIntervalSinceReferenceDate: TimeInterval($0 + createdAtOffset)),
                    cid: chat.cid
                )
            }
        return ChannelPayload.dummy(channel: .dummy(cid: chat.cid), messages: messages)
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
            channelUpdater = ChannelUpdater(
                channelRepository: client.channelRepository,
                callRepository: client.callRepository,
                messageRepository: client.messageRepository,
                paginationStateHandler: client.makeMessagesPaginationStateHandler(),
                database: client.databaseContainer,
                apiClient: client.apiClient
            )
            channelUpdaterMock = ChannelUpdater_Mock(
                channelRepository: client.channelRepository,
                callRepository: client.callRepository,
                messageRepository: client.messageRepository,
                paginationStateHandler: client.makeMessagesPaginationStateHandler(),
                database: client.databaseContainer,
                apiClient: client.apiClient
            )
        }
        
        lazy var chatEnvironment: Chat.Environment = .init(
            chatStateBuilder: { [unowned self] in
                self.chatState = ChatState(cid: $0, channelQuery: $1, clientConfig: $2, messageOrder: $3, memberListState: $4, authenticationRepository: $5, database: $6, eventNotificationCenter: $7, paginationStateHandler: $8)
                return self.chatState!
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
