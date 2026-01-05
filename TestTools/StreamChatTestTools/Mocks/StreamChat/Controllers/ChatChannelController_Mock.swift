//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

class ChatChannelController_Mock: ChatChannelController {
    var mockCid: ChannelId?
    override var cid: ChannelId? {
        mockCid ?? super.cid
    }

    var mockFirstUnreadMessageId: MessageId?
    override var firstUnreadMessageId: MessageId? {
        mockFirstUnreadMessageId ?? super.firstUnreadMessageId
    }

    /// Creates a new mock instance of `ChatChannelController`.
    static func mock(chatClientConfig: ChatClientConfig? = nil) -> ChatChannelController_Mock {
        .init(
            channelQuery: .init(cid: try! .init(cid: "mock:channel")),
            channelListQuery: nil,
            client: .mock(config: chatClientConfig)
        )
    }

    /// Creates a new mock instance of `ChatChannelController`.
    static func mock(chatClient: ChatClient_Mock) -> ChatChannelController_Mock {
        .init(
            channelQuery: .init(cid: try! .init(cid: "mock:channel")),
            channelListQuery: nil,
            client: chatClient
        )
    }

    static func mock(
        channelQuery: ChannelQuery,
        channelListQuery: ChannelListQuery?,
        client: ChatClient
    ) -> ChatChannelController_Mock {
        .init(
            channelQuery: channelQuery,
            channelListQuery: channelListQuery,
            client: client
        )
    }

    static func mock(client: ChatClient) -> ChatChannelController_Mock {
        .init(
            channelQuery: .init(cid: try! .init(cid: "mock:channel")),
            channelListQuery: nil,
            client: client
        )
    }

    var createNewMessageCallCount = 0
    override func createNewMessage(
        messageId: MessageId? = nil,
        text: String, pinning: MessagePinning? = nil,
        isSilent: Bool = false,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        quotedMessageId: MessageId? = nil,
        skipPush: Bool = false,
        skipEnrichUrl: Bool = false,
        restrictedVisibility: [UserId] = [],
        location: NewLocationInfo? = nil,
        extraData: [String: RawJSON] = [:],
        completion: ((Result<MessageId, Error>) -> Void)? = nil
    ) {
        createNewMessageCallCount += 1
    }

    var hasLoadedAllNextMessages_mock: Bool? = true
    override var hasLoadedAllNextMessages: Bool {
        hasLoadedAllNextMessages_mock ?? super.hasLoadedAllNextMessages
    }

    var hasLoadedAllPreviousMessages_mock: Bool? = true
    override var hasLoadedAllPreviousMessages: Bool {
        hasLoadedAllPreviousMessages_mock ?? super.hasLoadedAllPreviousMessages
    }

    var markedAsUnread_mock: Bool? = true
    override var isMarkedAsUnread: Bool {
        markedAsUnread_mock ?? super.isMarkedAsUnread
    }

    var channel_mock: ChatChannel?
    override var channel: ChatChannel? {
        channel_mock ?? super.channel
    }

    var channelQuery_mock: ChannelQuery?
    override var channelQuery: ChannelQuery {
        channelQuery_mock ?? super.channelQuery
    }

    var messages_mock: [ChatMessage]?
    override var messages: LazyCachedMapCollection<ChatMessage> {
        messages_mock.map { $0.lazyCachedMap { $0 } } ?? super.messages
    }

    var markReadCallCount = 0
    override func markRead(completion: ((Error?) -> Void)?) {
        markReadCallCount += 1
    }

    var state_mock: State?
    override var state: DataController.State {
        get { state_mock ?? super.state }
        set { super.state = newValue }
    }

    private(set) var synchronize_completion: ((Error?) -> Void)?
    override func synchronize(_ completion: ((Error?) -> Void)? = nil) {
        synchronize_completion = completion
    }

    var loadFirstPageCallCount = 0
    var loadFirstPage_result: Error?
    override func loadFirstPage(_ completion: ((Error?) -> Void)? = nil) {
        loadFirstPageCallCount += 1
        completion?(loadFirstPage_result)
    }

    var loadPageAroundMessageIdCallCount = 0
    override func loadPageAroundMessageId(
        _ messageId: MessageId,
        limit: Int? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        loadPageAroundMessageIdCallCount += 1
    }

    var updateDraftMessage_callCount = 0
    var updateDraftMessage_completion: ((Result<DraftMessage, any Error>) -> Void)?
    var updateDraftMessage_text = ""

    override func updateDraftMessage(
        text: String,
        isSilent: Bool = false,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        quotedMessageId: MessageId? = nil,
        command: Command? = nil,
        extraData: [String: RawJSON] = [:],
        completion: ((Result<DraftMessage, any Error>) -> Void)? = nil
    ) {
        updateDraftMessage_text = text
        updateDraftMessage_callCount += 1
        updateDraftMessage_completion = completion
    }

    var deleteDraftMessage_callCount = 0
    var deleteDraftMessage_completion: ((Error?) -> Void)?

    override func deleteDraftMessage(completion: ((Error?) -> Void)? = nil) {
        deleteDraftMessage_callCount += 1
        deleteDraftMessage_completion = completion
    }

    var loadDraftMessage_callCount = 0
    var loadDraftMessage_completion: ((Result<DraftMessage?, Error>) -> Void)?

    override func loadDraftMessage(completion: ((Result<DraftMessage?, Error>) -> Void)? = nil) {
        loadDraftMessage_callCount += 1
        loadDraftMessage_completion = completion
    }
}

extension ChatChannelController_Mock {
    /// Simulates the initial conditions. Setting these values doesn't trigger any observer callback.
    func simulateInitial(channel: ChatChannel, messages: [ChatMessage], state: DataController.State) {
        channel_mock = channel
        messages_mock = messages
        state_mock = state
    }

    /// Simulates a change of the `channel` value. Observers are notified with the provided `change` value. If `typingUsers`
    /// value is explicitly provided, `didChangeTypingUsers` is called, too.
    func simulate(
        channel: ChatChannel?,
        change: EntityChange<ChatChannel>,
        typingUsers: Set<ChatChannelMember>?
    ) {
        channel_mock = channel
        delegateCallback {
            $0.channelController(self, didUpdateChannel: change)
            if let typingUsers = typingUsers {
                $0.channelController(self, didChangeTypingUsers: typingUsers)
            }
        }
    }

    /// Simulates changes in the `messages` array. Observers are notified with the provided `changes` value.
    func simulate(messages: [ChatMessage], changes: [ListChange<ChatMessage>]) {
        messages_mock = messages
        delegateCallback {
            $0.channelController(self, didUpdateMessages: changes)
        }
    }

    /// Simulates a received member event.
    func simulate(memberEvent: MemberEvent) {
        delegateCallback {
            $0.channelController(self, didReceiveMemberEvent: memberEvent)
        }
    }

    /// Simulates changes of `state`. Observers are notified with the new value.
    func simulate(state: DataController.State) {
        state_mock = state
        delegateCallback {
            $0.controller(self, didChangeState: state)
        }
    }
}
