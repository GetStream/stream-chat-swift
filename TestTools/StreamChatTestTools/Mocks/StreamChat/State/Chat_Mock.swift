//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class Chat_Mock: Chat {

    static let cid = try! ChannelId(cid: "mock:channel")
    
    init(
        chatClient: ChatClient,
        channelQuery: ChannelQuery,
        channelListQuery: ChannelListQuery?
    ) {
        super.init(
            channelQuery: channelQuery,
            memberSorting: [.init(key: .createdAt)],
            client: chatClient
        )
    }
    
    /// Creates a new mock instance of `ChatChannelController`.
    public static func mock(
        chatClient: ChatClient? = nil,
        chatClientConfig: ChatClientConfig? = nil,
        bundle: Bundle? = nil
    ) -> Chat_Mock {
        let chatClient = chatClient ?? ChatClient.mock(config: chatClientConfig, bundle: bundle)
        return Chat_Mock(
            chatClient: chatClient,
            channelQuery: .init(cid: cid, channelQuery: .init(cid: cid)),
            channelListQuery: nil
        )
    }

    public static func mock(
        channelQuery: ChannelQuery,
        channelListQuery: ChannelListQuery?,
        client: ChatClient
    ) -> Chat_Mock {
        Chat_Mock(
            chatClient: client,
            channelQuery: channelQuery,
            channelListQuery: channelListQuery
        )
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
    
    public var loadPageAroundMessageIdCallCount = 0
    public override func loadMessages(around messageId: MessageId, limit: Int? = nil) async throws {
        loadPageAroundMessageIdCallCount += 1
    }
}

public extension Chat_Mock {
    /// Simulates the initial conditions. Setting these values doesn't trigger any observer callback.
    @MainActor func simulateInitial(channel: ChatChannel, messages: [ChatMessage]) {
        self.state.channel = channel
        self.state.messages = StreamCollection(messages)
    }

    /// Simulates a change of the `channel` value. Observers are notified with the provided `change` value.
    @MainActor func simulate(
        channel: ChatChannel?,
        change: EntityChange<ChatChannel>
    ) {
        self.state.channel = channel
    }

    /// Simulates changes in the `messages` array. Observers are notified with the provided `changes` value.
    @MainActor func simulate(messages: [ChatMessage], changes: [ListChange<ChatMessage>]) {
        var newMessages = messages
        for message in state.messages {
            newMessages.append(message)
        }
        
        self.state.messages = StreamCollection(newMessages)
    }
}
