//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class ChatChannelController_Mock: ChatChannelController {

    var mockCid: ChannelId?
    public override var cid: ChannelId? {
        mockCid ?? super.cid
    }

    var mockFirstUnreadMessageId: MessageId?
    public override var firstUnreadMessageId: MessageId? {
        mockFirstUnreadMessageId ?? super.firstUnreadMessageId
    }

    /// Creates a new mock instance of `ChatChannelController`.
    public static func mock(chatClientConfig: ChatClientConfig? = nil) -> ChatChannelController_Mock {
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

    public static func mock(
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

    public static func mock(client: ChatClient) -> ChatChannelController_Mock {
        .init(
            channelQuery: .init(cid: try! .init(cid: "mock:channel")),
            channelListQuery: nil,
            client: client
        )
    }

    var createNewMessageCallCount = 0
    public override func createNewMessage(
        messageId: MessageId? = nil,
        text: String, pinning: MessagePinning? = nil,
        isSilent: Bool = false,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        quotedMessageId: MessageId? = nil,
        skipPush: Bool = false,
        skipEnrichUrl: Bool = false,
        extraData: [String : RawJSON] = [:],
        completion: ((Result<MessageId, Error>) -> Void)? = nil
    ) {
        createNewMessageCallCount += 1
    }

    public var hasLoadedAllNextMessages_mock: Bool? = true
    public override var hasLoadedAllNextMessages: Bool {
        hasLoadedAllNextMessages_mock ?? super.hasLoadedAllNextMessages
    }

    public var hasLoadedAllPreviousMessages_mock: Bool? = true
    public override var hasLoadedAllPreviousMessages: Bool {
        hasLoadedAllPreviousMessages_mock ?? super.hasLoadedAllPreviousMessages
    }

    public var markedAsUnread_mock: Bool? = true
    public override var isMarkedAsUnread: Bool {
        markedAsUnread_mock ?? super.isMarkedAsUnread
    }

    public var channel_mock: ChatChannel?
    override public var channel: ChatChannel? {
        channel_mock ?? super.channel
    }

    public var channelQuery_mock: ChannelQuery?
    public override var channelQuery: ChannelQuery {
        channelQuery_mock ?? super.channelQuery
    }

    public var messages_mock: [ChatMessage]?
    override public var messages: LazyCachedMapCollection<ChatMessage> {
        messages_mock.map { $0.lazyCachedMap { $0 } } ?? super.messages
    }

    public var markReadCallCount = 0
    public override func markRead(completion: ((Error?) -> Void)?) {
        markReadCallCount += 1
    }

    public var state_mock: State?
    override public var state: DataController.State {
        get { state_mock ?? super.state }
        set { super.state = newValue }
    }

    public private(set) var synchronize_completion: ((Error?) -> Void)?
    override public func synchronize(_ completion: ((Error?) -> Void)? = nil) {
        synchronize_completion = completion
    }

    public var loadFirstPageCallCount = 0
    public var loadFirstPage_result: Error?
    public override func loadFirstPage(_ completion: ((Error?) -> Void)? = nil) {
        loadFirstPageCallCount += 1
        completion?(loadFirstPage_result)
    }

    public var loadPageAroundMessageIdCallCount = 0
    public override func loadPageAroundMessageId(
        _ messageId: MessageId,
        limit: Int? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        loadPageAroundMessageIdCallCount += 1
    }
}

public extension ChatChannelController_Mock {
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
