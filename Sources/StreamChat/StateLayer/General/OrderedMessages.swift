//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
struct OrderedMessages {
    let messageOrdering: MessageOrdering
    let orderedMessages: [ChatMessage]
    
    var ascendingSortedMessages: [ChatMessage] {
        messageOrdering.isAscending ? orderedMessages : orderedMessages.reversed()
    }
    
    private func ascendingToOrdered(_ messages: [ChatMessage]) -> [ChatMessage] {
        messageOrdering.isAscending ? messages : messages.reversed()
    }
    
    func withListChanges(_ changes: [ListChange<ChatMessage>]) -> [ChatMessage] {
        let ascendingSortedChanges = changes.sorted(by: { $0.indexPath < $1.indexPath })
        let ascendingSortedResult = ascendingSortedMessages.uniquelyApplied(ascendingSortedChanges)
        return ascendingToOrdered(ascendingSortedResult)
    }
    
    func withInsertingPaginated(_ newMessages: [ChatMessage], resetToLocalOnly: Bool) -> [ChatMessage] {
        let ascendingExistingMessages = resetToLocalOnly ? ascendingSortedMessages.filter { $0.isLocalOnly } : ascendingSortedMessages
        let ascendingSortedResult = ascendingExistingMessages.uniquelyMerged(newMessages)
        return ascendingToOrdered(ascendingSortedResult)
    }
}

private extension MessageOrdering {
    var isAscending: Bool {
        switch self {
        case .topToBottom: return false
        case .bottomToTop: return true
        }
    }
}
