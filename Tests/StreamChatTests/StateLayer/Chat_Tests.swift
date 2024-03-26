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
        setUpChat(.init(cid: channelId))
    }

    override func tearDownWithError() throws {
        env.cleanUp()
        channelId = nil
        chat = nil
        expectedTestError = nil
    }
    
    func setUpChat(_ query: ChannelQuery) {
        chat = Chat(
            cid: channelId,
            channelQuery: query,
            channelListQuery: nil,
            messageOrdering: .topToBottom,
            memberSorting: [Sorting(key: .createdAt)],
            channelUpdater: env.channelUpdater,
            client: env.client,
            environment: env.environment
        )
    }
    
    // MARK: - Deleting the Channel
    
    func test_delete_whenAPIRequestSucceeds_thenDeleteSucceeds() async throws {
        env.channelUpdater.deleteChannel_completion_next_result = .success(())
        try await chat.delete()
    }
    
    func test_delete_whenAPIRequestFails_thenDeleteFails() async throws {
        env.channelUpdater.deleteChannel_completion_next_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.delete(), expectedTestError)
    }
    
    // MARK: - Disabling/Freezing the Channel
    
    func test_freeze_whenAPIRequestSucceeds_thenFreezeSucceeds() async throws {
        env.channelUpdater.freezeChannel_completion_next_result = .success(())
        try await chat.freeze()
        XCTAssertEqual(channelId, env.channelUpdater.freezeChannel_cid)
        XCTAssertEqual(true, env.channelUpdater.freezeChannel_freeze)
    }
    
    func test_freeze_whenAPIRequestFails_thenFreezeFails() async throws {
        env.channelUpdater.freezeChannel_completion_next_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.freeze(), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdater.freezeChannel_cid)
        XCTAssertEqual(true, env.channelUpdater.freezeChannel_freeze)
    }
    
    func test_unfreeze_whenAPIRequestSucceeds_thenUnfreezeSucceeds() async throws {
        env.channelUpdater.freezeChannel_completion_next_result = .success(())
        try await chat.unfreeze()
        XCTAssertEqual(channelId, env.channelUpdater.freezeChannel_cid)
        XCTAssertEqual(false, env.channelUpdater.freezeChannel_freeze)
    }
    
    func test_unfreeze_whenAPIRequestFails_thenUnfreezeFails() async throws {
        env.channelUpdater.freezeChannel_completion_next_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.unfreeze(), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdater.freezeChannel_cid)
        XCTAssertEqual(false, env.channelUpdater.freezeChannel_freeze)
    }
    
    // MARK: - Invites
    
    func test_acceptInvite_whenAPIRequestSucceeds_thenAcceptInviteSucceeds() async throws {
        env.channelUpdater.acceptInvite_completion_next_result = .success(())
        try await chat.acceptInvite()
        XCTAssertEqual(channelId, env.channelUpdater.acceptInvite_cid)
        XCTAssertEqual(nil, env.channelUpdater.acceptInvite_message)
        
        env.channelUpdater.acceptInvite_completion_next_result = .success(())
        try await chat.acceptInvite(with: "My system message")
        XCTAssertEqual(channelId, env.channelUpdater.acceptInvite_cid)
        XCTAssertEqual("My system message", env.channelUpdater.acceptInvite_message)
    }
    
    func test_acceptInvite_whenAPIRequestFails_thenAcceptInviteFails() async throws {
        env.channelUpdater.acceptInvite_completion_next_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.acceptInvite(), expectedTestError)
        await XCTAssertAsyncFailure(try await chat.acceptInvite(with: "My system message"), expectedTestError)
    }
    
    func test_inviteMembers_whenAPIRequestSucceeds_thenInviteMembersSucceeds() async throws {
        let memberIds: [UserId] = [.unique, .unique]
        env.channelUpdater.inviteMembers_completion_next_result = .success(())
        try await chat.inviteMembers(memberIds)
        XCTAssertEqual(channelId, env.channelUpdater.inviteMembers_cid)
        XCTAssertEqual(memberIds.sorted(), env.channelUpdater.inviteMembers_userIds?.sorted())
    }
    
    func test_inviteMembers_whenAPIRequestFails_thenInviteMembersFails() async throws {
        let memberIds: [UserId] = [.unique, .unique]
        env.channelUpdater.inviteMembers_completion_next_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.inviteMembers(memberIds), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdater.inviteMembers_cid)
        XCTAssertEqual(memberIds.sorted(), env.channelUpdater.inviteMembers_userIds?.sorted())
    }
    
    func test_rejectMembers_whenAPIRequestSucceeds_thenRejectMembersSucceeds() async throws {
        env.channelUpdater.rejectInvite_completion_next_result = .success(())
        try await chat.rejectInvite()
        XCTAssertEqual(channelId, env.channelUpdater.rejectInvite_cid)
    }
    
    func test_rejectMembers_whenAPIRequestFails_thenRejectMembersFails() async throws {
        env.channelUpdater.rejectInvite_completion_next_result = .failure(expectedTestError)
        await XCTAssertAsyncFailure(try await chat.rejectInvite(), expectedTestError)
        XCTAssertEqual(channelId, env.channelUpdater.rejectInvite_cid)
    }
}

@available(iOS 13.0, *)
extension Chat_Tests {
    final class TestEnvironment {
        let client: ChatClient_Mock
        private(set) var chatState: ChatState!
        private(set) var channelUpdater: ChannelUpdater_Mock!
        private(set) var memberUpdater: ChannelMemberUpdater_Mock!
        private(set) var messageUpdater: MessageUpdater_Mock!
        private(set) var readStateSender: Chat.ReadStateSender!
        private(set) var typingEventsSender: TypingEventsSender_Mock!
        
        func cleanUp() {
            client.cleanUp()
            channelUpdater?.cleanUp()
            memberUpdater?.cleanUp()
            messageUpdater?.cleanUp()
            typingEventsSender?.cleanUp()
        }
        
        init() {
            client = ChatClient_Mock(
                config: ChatClient_Mock.defaultMockedConfig
            )
            channelUpdater = ChannelUpdater_Mock(
                channelRepository: client.channelRepository,
                callRepository: client.callRepository,
                messageRepository: client.messageRepository,
                paginationStateHandler: client.makeMessagesPaginationStateHandler(),
                database: client.databaseContainer,
                apiClient: client.apiClient
            )
        }
        
        lazy var environment: Chat.Environment = .init(
            chatStateBuilder: { [unowned self] in
                self.chatState = ChatState(cid: $0, channelQuery: $1, clientConfig: $2, messageOrder: $3, memberListState: $4, authenticationRepository: $5, database: $6, eventNotificationCenter: $7, paginationState: $8)
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
