//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

open class MessageCollectionView: UICollectionView {
    private var identifiers: Set<String> = .init()
    
    open var needsToScrollToMostRecentMessage = false
    open var needsToScrollToMostRecentMessageAnimated = false
    
    open func dequeueReusableCell<ExtraData: ExtraDataTypes>(
        withReuseIdentifier identifier: String,
        layoutOptions: ChatMessageLayoutOptions,
        for indexPath: IndexPath
    ) -> MessageCell<ExtraData> {
        let reuseIdentifier = "\(identifier)_\(layoutOptions.rawValue)"
        
        // There is no public API to find out
        // if the given `identifier` is registered.
        if !identifiers.contains(reuseIdentifier) {
            identifiers.insert(reuseIdentifier)
            
            register(MessageCell<ExtraData>.self, forCellWithReuseIdentifier: reuseIdentifier)
        }
            
        let cell = dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MessageCell<ExtraData>
        cell.messageContentView.setUpLayoutIfNeeded(options: layoutOptions)
        
        return cell
    }
    
    /// Updates the collection view data with given `changes`.
    open func updateMessages<ExtraData: ExtraDataTypes>(
        with changes: [ListChange<_ChatMessage<ExtraData>>],
        completion: ((Bool) -> Void)? = nil
    ) {
        performBatchUpdates {
            for change in changes {
                switch change {
                case let .insert(_, index):
                    insertItems(at: [index])
                case let .move(_, fromIndex, toIndex):
                    moveItem(at: fromIndex, to: toIndex)
                case let .remove(_, index):
                    deleteItems(at: [index])
                case let .update(_, index):
                    reloadItems(at: [index])
                }
            }
        } completion: { flag in
            completion?(flag)
        }
    }
    
    /// Will scroll to most recent message on next `updateMessages` call
    open func setNeedsScrollToMostRecentMessage(animated: Bool = true) {
        needsToScrollToMostRecentMessage = true
        needsToScrollToMostRecentMessageAnimated = animated
    }

    /// Force scroll to most recent message check without waiting for `updateMessages`
    open func scrollToMostRecentMessageIfNeeded() {
        guard needsToScrollToMostRecentMessage else { return }
        
        scrollToMostRecentMessage(animated: needsToScrollToMostRecentMessageAnimated)
    }

    /// Scrolls to most recent message
    open func scrollToMostRecentMessage(animated: Bool = true) {
        needsToScrollToMostRecentMessage = false

        // our collection is flipped, so (0; 0) item is most recent one
        scrollToItem(at: IndexPath(item: 0, section: 0), at: .bottom, animated: animated)
    }
}
