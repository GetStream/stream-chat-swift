//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Represents a list of message search results.
@MainActor public final class MessageSearchState: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private(set) var nextPageCursor: String?
    private let observer: Observer
    
    init(database: DatabaseContainer) {
        observer = Observer(database: database)
        observer.start(
            with: .init(messagesDidChange: { [weak self] in self?.messages = $0 })
        )
        $query
            .assign(to: \.query, on: observer)
            .store(in: &cancellables)
    }
    
    /// The message search query the messages match to.
    @Published public private(set) var query: MessageSearchQuery?
    
    /// An array of search results for the specified query and pagination state.
    @Published public internal(set) var messages = StreamCollection<ChatMessage>([])
    
    // MARK: - Mutating the State
    
    func set(query: MessageSearchQuery?, cursor: String?) {
        self.query = query
        nextPageCursor = cursor
    }
}
