//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

@available(iOS 13.0, *)
public class Chat_Mock: Chat {

    static let cid = try! ChannelId(cid: "mock:channel")
    
    /// Creates a new mock instance of `ChatChannelController`.
    public static func mock(chatClientConfig: ChatClientConfig? = nil) -> Chat_Mock {
        let chatClient = ChatClient.mock(config: chatClientConfig)
        return chatClient.makeChat(for: cid) as! Chat_Mock
    }

    /// Creates a new mock instance of `ChatChannelController`.
    static func mock(chatClient: ChatClient_Mock) -> Chat_Mock {
        return chatClient.makeChat(for: cid) as! Chat_Mock
    }

    public static func mock(
        channelQuery: ChannelQuery,
        channelListQuery: ChannelListQuery?,
        client: ChatClient
    ) async throws -> Chat_Mock {
        try await client.makeChat(with: channelQuery, channelListQuery: channelListQuery) as! Chat_Mock
    }

    var createNewMessageCallCount = 0
    public override func sendMessage(
        with text: String,
        attachments: [AnyAttachmentPayload] = [],
        quote quotedMessageId: MessageId? = nil,
        mentions: [UserId] = [],
        pinning: MessagePinning? = nil,
        extraData: [String : RawJSON] = [:],
        silent: Bool = false,
        skipPushNotification: Bool = false,
        skipEnrichURL: Bool = false,
        messageId: MessageId? = nil
    ) async throws -> ChatMessage {
        createNewMessageCallCount += 1
        return ChatMessage.mock()
    }

    public var channel_mock: ChatChannel?
    public var channel: ChatChannel? {
        channel_mock ?? super.state.channel
    }

    public var messages_mock: [ChatMessage]?
    public var messages: StreamCollection<ChatMessage> {
        messages_mock.map { StreamCollection($0) } ?? super.state.messages
    }
}

@available(iOS 13.0, *)
public extension Chat_Mock {
    /// Simulates the initial conditions. Setting these values doesn't trigger any observer callback.
    func simulateInitial(channel: ChatChannel, messages: [ChatMessage]) {
        channel_mock = channel
        messages_mock = messages
    }

    /// Simulates a change of the `channel` value. Observers are notified with the provided `change` value. If `typingUsers`
    /// value is explicitly provided, `didChangeTypingUsers` is called, too.
    func simulate(
        channel: ChatChannel?,
        change: EntityChange<ChatChannel>,
        typingUsers: Set<ChatChannelMember>?
    ) {
        channel_mock = channel
        self.state.channel = channel
        if let typingUsers {
            self.state.typingUsers = typingUsers
        }
    }

    /// Simulates changes in the `messages` array. Observers are notified with the provided `changes` value.
    func simulate(messages: [ChatMessage], changes: [ListChange<ChatMessage>]) {
        messages_mock = messages
        self.state.messages = StreamCollection(messages)
    }
}
