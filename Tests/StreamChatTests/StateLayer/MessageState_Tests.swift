//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageState_Tests: XCTestCase {
    private var channelId: ChannelId!
    private var env: TestEnvironment!
    private var messageId: MessageId!
    private var messageState: MessageState!
    private var testError: TestError!
    private var unrelatedMessageId: MessageId!
    
    override func setUpWithError() throws {
        channelId = .unique
        env = TestEnvironment()
        messageId = .unique
        unrelatedMessageId = .unique
        
        // Channel is required for saving messages
        env.client.databaseContainer.write { session in
            try session.saveChannel(payload: self.makeChannelPayload(messageId: nil))
        }
    }

    override func tearDownWithError() throws {
        env.cleanUp()
        channelId = nil
        env = nil
        messageId = nil
        messageState = nil
        unrelatedMessageId = nil
    }

    // MARK: - Observing Message
    
    func test_observingMessage_whenMessageChanges_thenStateChanges() async throws {
        try await setUpMessageState()
        XCTAssertEqual(nil, await messageState.message.localState)
        
        try await modifyMessage { dto in
            dto.localMessageState = .sendingFailed
        }
        XCTAssertEqual(LocalMessageState.sendingFailed, await messageState.message.localState)
    }
    
    // MARK: - Observing Reactions
    
    func test_restoringReactions_whenReactionsStored_thenInitialStateIsSet() async throws {
        let messagePayload = makeMessagePayload(reactionCount: 3, messageId: messageId)
        try await env.client.databaseContainer.write { session in
            try session.saveMessage(
                payload: messagePayload,
                for: self.channelId,
                syncOwnReactions: true,
                cache: nil
            )
            // Add reactions to other messages for ensuring MessageState does not pick them up
            try session.saveMessage(
                payload: self.makeMessagePayload(reactionCount: 3, messageId: self.unrelatedMessageId),
                for: self.channelId,
                syncOwnReactions: true,
                cache: nil
            )
        }
        
        try await setUpMessageState(writeMessages: false)
        // Default sorting is updatedAt and ascending (generated payload is sorted like this)
        XCTAssertEqual(messagePayload.latestReactions.map(\.updatedAt), await messageState.reactions.map(\.updatedAt))
    }
    
    func test_observingReactions_whenReactionsChange_thenStateChanges() async throws {
        try await setUpMessageState()
        XCTAssertEqual(0, await messageState.reactions.count)
        
        let messagePayload = makeMessagePayload(reactionCount: 3, messageId: messageId)
        try await env.client.databaseContainer.write { session in
            try session.saveMessage(
                payload: messagePayload,
                for: self.channelId,
                syncOwnReactions: true,
                cache: nil
            )
            // Add reactions to other messages for ensuring MessageState does not pick them up
            try session.saveMessage(
                payload: self.makeMessagePayload(reactionCount: 3, messageId: self.unrelatedMessageId),
                for: self.channelId,
                syncOwnReactions: true,
                cache: nil
            )
        }
        
        // Default sorting is updatedAt and ascending (generated payload is sorted like this)
        XCTAssertEqual(messagePayload.latestReactions.map(\.updatedAt), await messageState.reactions.map(\.updatedAt))
    }
    
    // MARK: - Observing Replies
    
    func test_restoringReplies_whenRepliesStored_thenInitialStateIsSet() async throws {
        let replyPayloads = makeMessageRepliesPayload(repliesCount: 3, parentMessageId: messageId)
        try await env.client.databaseContainer.write { session in
            for replyPayload in replyPayloads {
                let message = try session.saveMessage(
                    payload: replyPayload,
                    for: self.channelId,
                    syncOwnReactions: true,
                    cache: nil
                )
                message.showInsideThread = true
            }
            // Unrelated
            let unrelatedReplies = self.makeMessageRepliesPayload(repliesCount: 5, parentMessageId: self.unrelatedMessageId)
            for replyPayload in unrelatedReplies {
                let message = try session.saveMessage(
                    payload: replyPayload,
                    for: self.channelId,
                    syncOwnReactions: true,
                    cache: nil
                )
                message.showInsideThread = true
            }
        }
        
        try await setUpMessageState()
        
        XCTAssertEqual(3, await messageState.replies.count)
        XCTAssertEqual(replyPayloads.map(\.id), await messageState.replies.map(\.id))
    }
    
    func test_observingReplies_whenRepliesChange_thenStateChanges() async throws {
        try await setUpMessageState()
        XCTAssertEqual(0, await messageState.replies.count)
        
        let replyPayloads = makeMessageRepliesPayload(repliesCount: 3, parentMessageId: messageId)
        try await env.client.databaseContainer.write { session in
            for replyPayload in replyPayloads {
                let message = try session.saveMessage(
                    payload: replyPayload,
                    for: self.channelId,
                    syncOwnReactions: true,
                    cache: nil
                )
                message.showInsideThread = true
            }
            // Unrelated
            let unrelatedReplies = self.makeMessageRepliesPayload(repliesCount: 5, parentMessageId: self.unrelatedMessageId)
            for replyPayload in unrelatedReplies {
                let message = try session.saveMessage(
                    payload: replyPayload,
                    for: self.channelId,
                    syncOwnReactions: true,
                    cache: nil
                )
                message.showInsideThread = true
            }
        }
        
        XCTAssertEqual(3, await messageState.replies.count)
        XCTAssertEqual(replyPayloads.map(\.id), await messageState.replies.map(\.id))
    }
    
    // MARK: - Test Data
    
    private func setUpMessageState(writeMessages: Bool = true) async throws {
        if writeMessages {
            try await env.client.databaseContainer.write { session in
                try session.saveChannel(payload: self.makeChannelPayload(messageId: self.messageId))
                try session.saveChannel(payload: self.makeChannelPayload(messageId: self.unrelatedMessageId))
            }
        }
        
        let message = try await env.client.databaseContainer.read { context in
            guard let dto = context.message(id: self.messageId) else { throw ClientError.MessageDoesNotExist(messageId: self.messageId) }
            return try dto.asModel()
        }
        await MainActor.run {
            messageState = MessageState(
                message: message,
                messageOrder: .bottomToTop,
                database: env.client.databaseContainer,
                clientConfig: env.client.config,
                replyPaginationHandler: env.client.makeMessagesPaginationStateHandler()
            )
        }
    }
    
    private func modifyMessage(_ block: @escaping (MessageDTO) -> Void) async throws {
        try await env.client.databaseContainer.write { session in
            guard let dto = session.message(id: self.messageId) else { throw ClientError.MessageDoesNotExist(messageId: self.messageId) }
            block(dto)
        }
    }
    
    private func makeChannelPayload(messageId: MessageId?) -> ChannelPayload {
        // Note that message pagination relies on createdAt and cid
        var messages = [MessagePayload]()
        if let messageId {
            messages.append(
                MessagePayload.dummy(
                    messageId: messageId,
                    createdAt: Date(timeIntervalSinceReferenceDate: 0),
                    cid: .unique
                )
            )
        }
        return ChannelPayload.dummy(channel: .dummy(cid: channelId), messages: messages)
    }
    
    private func makeMessagePayload(reactionCount: Int, messageId: MessageId) -> MessagePayload {
        let reactions = (0..<reactionCount)
            .reversed() // last updated ones first
            .map {
                MessageReactionPayload.dummy(
                    messageId: messageId,
                    updatedAt: Date(timeIntervalSinceReferenceDate: TimeInterval($0)),
                    user: .dummy(userId: .unique)
                )
            }
        return MessagePayload.dummy(messageId: messageId, latestReactions: reactions)
    }
    
    private func makeMessageRepliesPayload(repliesCount: Int, parentMessageId: MessageId) -> [MessagePayload] {
        (0..<repliesCount)
            .map {
                MessagePayload.dummy(
                    messageId: "\(parentMessageId)_reply_\($0)",
                    parentId: parentMessageId,
                    createdAt: Date(timeIntervalSinceReferenceDate: TimeInterval($0)),
                    cid: channelId
                )
            }
    }
}

extension MessageState_Tests {
    final class TestEnvironment {
        let client: ChatClient_Mock
        private(set) var state: MessageSearchState!
        private(set) var messageUpdater: MessageUpdater!
        
        func cleanUp() {
            client.cleanUp()
        }
        
        init() {
            client = ChatClient_Mock(
                config: ChatClient_Mock.defaultMockedConfig
            )
            messageUpdater = MessageUpdater(
                isLocalStorageEnabled: true,
                messageRepository: client.mockMessageRepository,
                database: client.mockDatabaseContainer,
                apiClient: client.mockAPIClient
            )
        }
    }
}
