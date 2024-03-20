//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Represents a list of message search results.
@available(iOS 13.0, *)
public final class MessageSearchState: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private(set) var nextPageCursor: String?
    private let observer: Observer
    let explicitFilterHash = UUID().uuidString
    
    init(database: DatabaseContainer) {
        observer = Observer(database: database)
        observer.start(
            with: .init(messagesDidChange: { [weak self] in await self?.setValue($0, for: \.messages) })
        )
        $query
            .assign(to: \.query, on: observer)
            .store(in: &cancellables)
    }
    
    /// The message search query the messages match to.
    @Published public private(set) var query: MessageSearchQuery?
    
    /// An array of search results for the specified query and pagination state.
    @Published public private(set) var messages = StreamCollection<ChatMessage>([])
    
    // MARK: - Mutating the State
    
    @MainActor func value<Value>(forKeyPath keyPath: KeyPath<MessageSearchState, Value>) -> Value {
        self[keyPath: keyPath]
    }
    
    @MainActor func setValue<Value>(_ value: Value, for keyPath: ReferenceWritableKeyPath<MessageSearchState, Value>) {
        self[keyPath: keyPath] = value
    }
    
    @MainActor func set(query: MessageSearchQuery, cursor: String?) {
        self.query = query
        nextPageCursor = cursor
    }
}
