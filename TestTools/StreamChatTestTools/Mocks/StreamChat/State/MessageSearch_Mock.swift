//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class MessageSearch_Mock: MessageSearch, @unchecked Sendable {
    public static func mock(client: ChatClient? = nil) -> MessageSearch_Mock {
        .init(client: client ?? .mock(bundle: Bundle(for: Self.self)))
    }

    @MainActor public var messages_mock: [ChatMessage]? {
        didSet {
            state.messages = messages_mock ?? []
        }
    }
    
    @MainActor public var messages: [ChatMessage] {
        messages_mock ?? super.state.messages
    }

    var loadNextMessagesCallCount = 0
    override public func loadMoreMessages(limit: Int? = nil) async throws -> [ChatMessage] {
        loadNextMessagesCallCount += 1
        return await state.messages
    }
    
    var searchCallCount = 0
    override public func search(query: MessageSearchQuery) async throws -> [ChatMessage] {
        searchCallCount += 1
        return await MainActor.run {
            state.messages = messages
            return messages
        }
    }

    override public func search(text: String) async throws -> [ChatMessage] {
        searchCallCount += 1
        return await MainActor.run {
            state.messages = messages
            return messages
        }
    }
}
