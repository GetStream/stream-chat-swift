//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The collection view that provides convenient API for dequeuing `_СhatMessageCollectionViewCell` instances
/// with the provided content view type and layout options.
open class ChatMessageListCollectionView: UICollectionView {
    private var identifiers: Set<String> = .init()
    
    open var needsToScrollToMostRecentMessage = false
    open var needsToScrollToMostRecentMessageAnimated = false

    /// Dequeues the message cell. Registers the cell for received combination of `contentViewClass + layoutOptions`
    /// if needed.
    /// - Parameters:
    ///   - contentViewClass: The type of content view the cell will be displaying.
    ///   - layoutOptions: The option set describing content view layout.
    ///   - indexPath: The cell index path.
    /// - Returns: The instance of `_СhatMessageCollectionViewCell<ExtraData>` set up with the
    /// provided `contentViewClass` and `layoutOptions`
    open func dequeueReusableCell<ExtraData: ExtraDataTypes>(
        contentViewClass: _ChatMessageContentView<ExtraData>.Type,
        attachmentViewInjectorType: _AttachmentViewInjector<ExtraData>.Type?,
        layoutOptions: ChatMessageLayoutOptions,
        for indexPath: IndexPath
    ) -> _СhatMessageCollectionViewCell<ExtraData> {
        let reuseIdentifier =
            "\(_СhatMessageCollectionViewCell<ExtraData>.reuseId)_" + "\(layoutOptions.rawValue)_" +
            "\(contentViewClass)_" + String(describing: attachmentViewInjectorType)

        // There is no public API to find out
        // if the given `identifier` is registered.
        if !identifiers.contains(reuseIdentifier) {
            identifiers.insert(reuseIdentifier)
            
            register(_СhatMessageCollectionViewCell<ExtraData>.self, forCellWithReuseIdentifier: reuseIdentifier)
        }
            
        let cell = dequeueReusableCell(
            withReuseIdentifier: reuseIdentifier,
            for: indexPath
        ) as! _СhatMessageCollectionViewCell<ExtraData>
        cell.setMessageContentIfNeeded(
            contentViewClass: contentViewClass,
            attachmentViewInjectorType: attachmentViewInjectorType,
            options: layoutOptions
        )
        cell.messageContentView?.indexPath = { [weak cell, weak self] in
            guard let cell = cell else { return nil }
            return self?.indexPath(for: cell)
        }

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
