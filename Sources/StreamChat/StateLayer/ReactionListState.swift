//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a list of reactions matching to the specified query.
@MainActor public final class ReactionListState: ObservableObject {
    private let observer: Observer
    
    init(query: ReactionListQuery, database: DatabaseContainer) {
        self.query = query
        observer = Observer(query: query, database: database)
        reactions = observer.start(
            with: .init(reactionsDidChange: { [weak self] in self?.reactions = $0 })
        )
    }
    
    /// The query specifying and filtering the list of reactions.
    public let query: ReactionListQuery
    
    /// An array of reactions for the specified ``ReactionListQuery``.
    @Published public private(set) var reactions = StreamCollection<ChatMessageReaction>([])
}
