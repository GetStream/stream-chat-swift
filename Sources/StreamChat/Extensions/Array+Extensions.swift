//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension Array where Element == ChatMessage {
    func uniquelyApplied(_ changes: [ListChange<Element>]) -> [Element] {
        var removedIds = Set<MessageId>()
        var newSortedMessages = [Element]()
        newSortedMessages.reserveCapacity(changes.count)
        
        for change in changes {
            if change.isRemove {
                removedIds.insert(change.item.id)
            } else {
                newSortedMessages.append(change.item)
            }
        }
        
        var result = self
        if !removedIds.isEmpty {
            result.removeAll(where: { removedIds.contains($0.id) })
        }
        
        newSortedMessages = newSortedMessages.sort(using: [.init(keyPath: \.createdAt, isAscending: true)])
        return result.uniquelyMerged(newSortedMessages)
    }
}
