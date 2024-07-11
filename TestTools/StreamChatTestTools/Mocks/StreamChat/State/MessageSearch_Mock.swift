//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class MessageSearch_Mock: MessageSearch {
    public static func mock(client: ChatClient? = nil) -> MessageSearch_Mock {
        .init(client: client ?? .mock(bundle: Bundle(for: Self.self)))
    }

    @MainActor public var messages_mock: StreamCollection<ChatMessage>? {
        didSet {
            state.messages = messages_mock ?? .init([])
        }
    }
    
    @MainActor public var messages: StreamCollection<ChatMessage> {
        messages_mock ?? super.state.messages
    }

    var loadNextMessagesCallCount = 0
    public override func loadMoreMessages(limit: Int? = nil) async throws -> [ChatMessage] {
        loadNextMessagesCallCount += 1
        return await Array(state.messages)
    }
    
    var searchCallCount = 0
    public override func search(query: MessageSearchQuery) async throws -> [ChatMessage] {
        searchCallCount += 1
        return await MainActor.run {
            state.messages = messages
            return Array(messages)
        }
    }

    public override func search(text: String) async throws -> [ChatMessage] {
        searchCallCount += 1
        return await MainActor.run {
            state.messages = messages
            return Array(messages)
        }
    }
}
