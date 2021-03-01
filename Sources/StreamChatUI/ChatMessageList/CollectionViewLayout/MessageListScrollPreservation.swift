//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// Protocol wrapping scroll offset preservation when changes to `ChatMessageListCollectionViewLayout` occur
public protocol MessageListScrollPreservation {
    /// Prepare for updates - useful for storing enough information to be able to decide about scroll offset later
    func prepareForUpdates(in layout: ChatMessageListCollectionViewLayout)
    /// Here you should perform any updates to scroll offset
    func finalizeUpdates(in layout: ChatMessageListCollectionViewLayout, animated: Bool)
}

/// Strategy that scrolls to most recent message after update if most recent message was visible before the update
open class MessageListMostRecentMessagePreservation: MessageListScrollPreservation {
    open var mostRecentMessageWasVisible = false
    
    public init() {
        
    }
    
    open func prepareForUpdates(in layout: ChatMessageListCollectionViewLayout) {
        mostRecentMessageWasVisible = layout.collectionView?.indexPathsForVisibleItems.contains(layout.mostRecentItem) ?? false
    }
    
    open func finalizeUpdates(in layout: ChatMessageListCollectionViewLayout, animated: Bool) {
        if mostRecentMessageWasVisible {
            layout.collectionView?.scrollToItem(at: layout.mostRecentItem, at: .bottom, animated: animated)
        }
        
        mostRecentMessageWasVisible = false
    }
}
