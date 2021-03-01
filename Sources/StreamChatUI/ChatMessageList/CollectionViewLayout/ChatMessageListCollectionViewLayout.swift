//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// Custom Table View like layout that position item at index path 0-0 on bottom of the list.
///
/// Unlike `UICollectionViewFlowLayout` we ignore some invalidation calls and persist items attributes between updates.
/// This resolves problem when on item reload layout would change content offset and user ends up on completely different item.
/// Layout intended for batch updates and right now I have no idea how it will react to `collectionView.reloadData()`.
open class ChatMessageListCollectionViewLayout: UICollectionViewLayout {
    public struct LayoutItem {
        let id = UUID()
        public var offset: CGFloat
        public var height: CGFloat

        public var maxY: CGFloat {
            offset + height
        }

        public init(offset: CGFloat, height: CGFloat) {
            self.offset = offset
            self.height = height
        }

        public func attribute(for index: Int, width: CGFloat) -> UICollectionViewLayoutAttributes {
            let attribute = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: 0))
            attribute.frame = CGRect(x: 0, y: offset, width: width, height: height)
            return attribute
        }
    }
    
    /// IndexPath for most recent message
    public let mostRecentItem = IndexPath(item: 0, section: 0)

    /// Layout items before currently running batch update
    open var previousItems: [LayoutItem] = []
    /// Actual layout
    open var currentItems: [LayoutItem] = []

    /// With better approximation you are getting better performance
    open var estimatedItemHeight: CGFloat = 200
    /// Vertical spacing between items
    open var spacing: CGFloat = 4

    /// Items that have been added to collectionview during currently running batch updates
    open var appearingItems: Set<IndexPath> = []
    /// Items that have been removed from collectionview during currently running batch updates
    open var disappearingItems: Set<IndexPath> = []
    /// We need to cache attributes used for initial/final state of added/removed items to update them after AutoLayout pass.
    /// This will prevent items to appear with `estimatedItemHeight` and animating to real size
    open var animatingAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]

    override open var collectionViewContentSize: CGSize {
        CGSize(
            width: collectionView!.bounds.width,
            height: currentItems.first?.maxY ?? 0
        )
    }
    
    /// Shortcut to determine if `collectionView` is currently scrolling
    open var isScrolling: Bool { collectionView.map { $0.isDragging || $0.isDecelerating } ?? false }

    open var currentCollectionViewWidth: CGFloat = 0

    /// Used to prevent layout issues during batch updates.
    ///
    /// Before batch updates collection view says to invalidate layout with `invalidateDataSourceCounts`.
    /// Next it ask us for attributes for new items before says which items are new. So we have no way to properly calculate it.
    /// `UICollectionViewFlowLayout` uses private API to get this info. We are don not have such privilege.
    /// If we return wrong attributes user will see artifacts and broken layout during batch update animation.
    /// By not returning any attributes during batch updates we are able to prevent such artifacts.
    open var preBatchUpdatesCall = false
    
    /// Object that takes care of preserving correct scroll offset after layout updates
    public let scrollPreservation: MessageListScrollPreservation

    // MARK: - Initialization

    override public required init() {
        scrollPreservation = MessageListMostRecentMessagePreservation()
        super.init()
    }
    
    internal init(scrollPreservation: MessageListScrollPreservation) {
        self.scrollPreservation = scrollPreservation
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.scrollPreservation = MessageListMostRecentMessagePreservation()
        super.init(coder: coder)
    }

    // MARK: - Layout invalidation

    override open func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        preBatchUpdatesCall = context.invalidateDataSourceCounts &&
            !context.invalidateEverything
        super.invalidateLayout(with: context)
    }

    override open func shouldInvalidateLayout(
        forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
        withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes
    ) -> Bool {
        let idx = originalAttributes.indexPath.item
        return preferredAttributes.frame.minY != currentItems[idx].offset
            || preferredAttributes.frame.height != currentItems[idx].height
    }

    override open func invalidationContext(
        forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
        withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutInvalidationContext {
        let invalidationContext = super.invalidationContext(
            forPreferredLayoutAttributes: preferredAttributes,
            withOriginalAttributes: originalAttributes
        )
        let idx = originalAttributes.indexPath.item

        let delta = preferredAttributes.frame.height - currentItems[idx].height
        currentItems[idx].height = preferredAttributes.frame.height
        // if item have been inserted recently or deleted, we need to update its attributes to prevent weird flickering
        animatingAttributes[preferredAttributes.indexPath]?.frame.size.height = preferredAttributes.frame.height

        // we are bottom-top layout with 0 being most bottom item. So when item X changes its attributes, it affect all
        // items before it in [0; X] range.
        let invalidNow = (0...idx).map { IndexPath(item: $0, section: 0) }
        invalidationContext.invalidateItems(at: invalidNow)

        for i in 0..<idx {
            currentItems[i].offset += delta
        }
        invalidationContext.contentSizeAdjustment = CGSize(width: 0, height: delta)

        // when we scrolling up and item above screens top edge changes its attributes it will push all items below it to bottom
        // making unpleasant jump. To prevent it we need to adjust current content offset by item delta
        let isSizingElementAboveTopEdge = originalAttributes.frame.minY < (collectionView?.contentOffset.y ?? 0)
        // when collection view is idle and one of items change its attributes we adjust content offset to stick with bottom item
        if isSizingElementAboveTopEdge || !isScrolling {
            invalidationContext.contentOffsetAdjustment = CGPoint(x: 0, y: delta)
        }

        return invalidationContext
    }

    // MARK: - Animation updates

    override open func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        scrollPreservation.prepareForUpdates(in: self)
        
        previousItems = currentItems
        let delete: (UICollectionViewUpdateItem) -> Void = { update in
            guard let ip = update.indexPathBeforeUpdate else { return }
            let idx = ip.item
            self.disappearingItems.insert(ip)
            var delta = self.currentItems[idx].height
            if idx > 0 {
                delta += self.spacing
            }
            for i in 0..<idx {
                self.currentItems[i].offset -= delta
            }
            self.currentItems.remove(at: idx)
        }

        let insert: (UICollectionViewUpdateItem) -> Void = { update in
            guard let ip = update.indexPathAfterUpdate else { return }
            self.appearingItems.insert(ip)
            let idx = ip.item
            let item: LayoutItem
            if idx == self.currentItems.count {
                item = LayoutItem(offset: 0, height: self.estimatedItemHeight)
            } else {
                item = LayoutItem(
                    offset: self.currentItems[idx].maxY + self.spacing,
                    height: self.currentItems[idx].height
                )
            }
            let delta = item.height + self.spacing
            for i in 0..<idx {
                self.currentItems[i].offset += delta
            }
            self.currentItems.insert(item, at: idx)
        }

        for update in updateItems {
            switch update.updateAction {
            case .delete:
                delete(update)
            case .insert:
                insert(update)
            case .move:
                delete(update)
                insert(update)
            case .reload, .none: break
            @unknown default: break
            }
        }

        preBatchUpdatesCall = false
        super.prepare(forCollectionViewUpdates: updateItems)
    }

    override open func finalizeCollectionViewUpdates() {
        let animatedScroll = appearingItems.contains(mostRecentItem)
        
        appearingItems.removeAll()
        disappearingItems.removeAll()
        animatingAttributes.removeAll()
        super.finalizeCollectionViewUpdates()
        
        // for some reason when adding / deleting items cv do not reload attributes for rows out of view
        // this will force reload
        invalidateLayout()
        
        scrollPreservation.finalizeUpdates(in: self, animated: animatedScroll)
    }

    // MARK: - Main layout access

    override open func prepare() {
        super.prepare()

        guard currentItems.isEmpty else { return }
        guard let cv = collectionView else { return }
        currentCollectionViewWidth = cv.bounds.width

        let count = cv.numberOfItems(inSection: 0)
        guard count > 0 else { return } // swiftlint:disable:this empty_count

        let height = estimatedItemHeight * CGFloat(count) + spacing * CGFloat(count - 1)
        var offset: CGFloat = height
        for _ in 0..<count {
            offset -= estimatedItemHeight
            let item = LayoutItem(offset: offset, height: estimatedItemHeight)
            currentItems.append(item)
            offset -= spacing
        }

        // scroll to make first item visible
        cv.contentOffset.y = currentItems[0].maxY - cv.bounds.height + cv.contentInset.bottom
    }

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard !preBatchUpdatesCall else { return nil }

        return currentItems
            .enumerated()
            .filter { _, item in
                let isBeforeRect = item.offset < rect.minY && item.maxY < rect.minY
                let isAfterRect = rect.minY < item.offset && rect.maxY < item.offset
                return !(isBeforeRect || isAfterRect)
            }
            .map {
                $1.attribute(for: $0, width: currentCollectionViewWidth)
            }
    }

    // MARK: - Layout for collection view items

    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard !preBatchUpdatesCall else { return nil }

        guard indexPath.item < currentItems.count else { return nil }
        let idx = indexPath.item
        return currentItems[idx].attribute(for: idx, width: currentCollectionViewWidth)
    }

// For now commented out - will be returned in near future when appearance glitch is resolved - added items are initally
// shortly visible on incorrect coordinates which doesn't look good on initial load
//
//    override open func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
//        let idx = itemIndexPath.item
//        if appearingItems.contains(itemIndexPath) {
//            // this is item that have been inserted into collection view in current batch update
//            let attribute = currentItems[idx].attribute(for: idx, width: currentCollectionViewWidth)
//            animatingAttributes[itemIndexPath] = attribute
//            return attribute
//        } else {
//            // this is item that already presented in collection view, but collection view decided to reload it
//            // by removing and inserting it back (4head)
//            // to properly animate possible change of such item, we need to return its attributes BEFORE batch update
//            guard let id = idForItem(at: idx) else { return nil }
//            return oldIdxForItem(with: id).map { oldIdx in
//                previousItems[oldIdx].attribute(for: oldIdx, width: currentCollectionViewWidth)
//            }
//        }
//    }

//    override open func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
//        let idx = itemIndexPath.item
//        guard let id = oldIdForItem(at: idx) else { return nil }
//        if disappearingItems.contains(itemIndexPath) {
//            // item gets removed from collection view, we don't do any special delete animations for now, so just return
//            // item attributes BEFORE batch update and let it fade away
//            let attribute = previousItems[idx].attribute(for: idx, width: currentCollectionViewWidth)
//            attribute.alpha = 0
//            return attribute
//        } else if let newIdx = idxForItem(with: id) {
//            // this is item that will stay in collection view, but collection view decided to reload it
//            // by removing and inserting it back (4head)
//            // to properly animate possible change of such item, we need to return its attributes AFTER batch update
//            let attribute = currentItems[newIdx].attribute(for: newIdx, width: currentCollectionViewWidth)
//            animatingAttributes[attribute.indexPath] = attribute
//            return attribute
//        }
//
//        return super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
//    }

    // MARK: - Access Layout Item

    open func idForItem(at idx: Int) -> UUID? {
        guard previousItems.indices.contains(idx) else { return nil }
        return currentItems[idx].id
    }

    open func idxForItem(with id: UUID) -> Int? {
        currentItems.firstIndex { $0.id == id }
    }

    open func oldIdForItem(at idx: Int) -> UUID? {
        guard previousItems.indices.contains(idx) else { return nil }
        return previousItems[idx].id
    }

    open func oldIdxForItem(with id: UUID) -> Int? {
        previousItems.firstIndex { $0.id == id }
    }
}
