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
            // default `zIndex` value is 0, but for some undocumented reason self-sizing
            // (concretely `contentView.systemLayoutFitting(...)`) doesn't work correctly,
            // so we need to make sure we do not use it, we need to add 1 so indexPath 0-0 doesn't have
            // problematic 0 zIndex
            attribute.zIndex = index + 1
            return attribute
        }
    }

    /// Layout items before currently running batch update
    open var previousItems: [LayoutItem] = []
    /// Actual layout
    open var currentItems: [LayoutItem] = []

    /// With better approximation you are getting better performance
    open var estimatedItemHeight: CGFloat = 200
    /// Vertical spacing between items
    open var spacing: CGFloat = 2

    /// Items that have been added to collectionview during currently running batch updates
    open var appearingItems: Set<IndexPath> = []
    /// Items that have been removed from collectionview during currently running batch updates
    open var disappearingItems: Set<IndexPath> = []
    /// We need to cache attributes used for initial/final state of added/removed items to update them after AutoLayout pass.
    /// This will prevent items to appear with `estimatedItemHeight` and animating to real size
    open var animatingAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]

    override open var collectionViewContentSize: CGSize {
        // This is a workaround for `layoutAttributesForElementsInRect:` not getting invoked enough
        // times if `collectionViewContentSize.width` is not smaller than the width of the collection
        // view, minus horizontal insets. This results in visual defects when performing batch
        // updates. To work around this, we subtract 0.0001 from our content size width calculation;
        // this small decrease in `collectionViewContentSize.width` is enough to work around the
        // incorrect, internal collection view `CGRect` checks, without introducing any visual
        // differences for elements in the collection view.
        // See https://openradar.appspot.com/radar?id=5025850143539200 for more details.
        //
        // Credit to https://github.com/airbnb/MagazineLayout/blob/6f88742c282de208e48cb738a7a14b7dc2651701/MagazineLayout/Public/MagazineLayout.swift#L69
        CGSize(
            width: collectionView!.bounds.width - 0.0001,
            height: currentItems.first?.maxY ?? 0
        )
    }

    open var currentCollectionViewWidth: CGFloat = 0

    /// Used to prevent layout issues during batch updates.
    ///
    /// Before batch updates collection view says to invalidate layout with `invalidateDataSourceCounts`.
    /// Next it ask us for attributes for new items before says which items are new. So we have no way to properly calculate it.
    /// `UICollectionViewFlowLayout` uses private API to get this info. We are don not have such privilege.
    /// If we return wrong attributes user will see artifacts and broken layout during batch update animation.
    /// By not returning any attributes during batch updates we are able to prevent such artifacts.
    open var preBatchUpdatesCall = false
    
    /// As we very often need to preserve scroll offset after performBatchUpdates, the simplest solution is to save original
    /// contentOffset and set it when batch updates end
    private var restoreOffset: CGFloat?

    /// Flag to make sure the `prepare()` function is only executed when the collection view had been loaded.
    /// The rest of the updates should come from `prepare(forCollectionViewUpdates:)`.
    private var didPerformInitialLayout = false
    
    /// When `true` the `restoreOffset` is returned from `targetContentOffset(forProposedContentOffset:)`
    /// which scrolls the message list to the bottom.
    private var didPerformInitialScrollToBottom = false

    // MARK: - Initialization

    override public required init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
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
        preferredAttributes.size.height != originalAttributes.size.height
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

        for i in 0..<idx {
            currentItems[i].offset += delta
        }
        invalidationContext.contentSizeAdjustment = CGSize(width: 0, height: delta)

        // when we scrolling up and item above screens top edge changes its attributes it will push all items below it to bottom
        // making unpleasant jump. To prevent it we need to adjust current content offset by item delta
        let isSizingElementAboveTopEdge = originalAttributes.frame.minY < (collectionView?.contentOffset.y ?? 0)
        // when collection view is idle and one of items change its attributes we adjust content offset to stick with bottom item
        let isScrolling: Bool = {
            guard let cv = collectionView else { return false }
            return cv.isDragging || cv.isDecelerating
        }()
        if isSizingElementAboveTopEdge || !isScrolling {
            invalidationContext.contentOffsetAdjustment = CGPoint(x: 0, y: delta)
        }

        return invalidationContext
    }
    
    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        collectionView.map { $0.bounds.size != newBounds.size } ?? true
    }
    
    override open func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        
        guard let collectionView = collectionView else { return context }
        
        let delta = newBounds.height - collectionView.bounds.height
        
        // If collectionView is shrinking and most recent message is visible, we will make sure it is still fully visible,
        // but if the conversation is short and not scrollable, this adjustment would be unwanted
        if delta < 0,
           collectionView.indexPathsForVisibleItems.contains(IndexPath(item: 0, section: 0)),
           collectionView.contentOffset.y > -collectionView.contentInset.top {
            context.contentOffsetAdjustment = CGPoint(x: 0, y: -delta)
        }

        return context
    }

    // MARK: - Animation updates

    open func _prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        previousItems = currentItems
        
        // used to determine what contentOffset should be restored after batch updates
        restoreOffset = collectionView.map { collectionViewContentSize.height - $0.contentOffset.y }
        
        let delete: (UICollectionViewUpdateItem) -> Void = { update in
            guard let ip = update.indexPathBeforeUpdate else { return }
            let idx = ip.item
            let item = self.previousItems[idx]
            self.disappearingItems.insert(ip)
            var delta = item.height
            if idx > 0 {
                delta += self.spacing
            }
            for i in 0..<idx {
                guard let oldId = self.oldIdForItem(at: i) else { return }
                
                if let idx = self.idxForItem(with: oldId) {
                    self.currentItems[idx].offset -= delta
                }
            }
            
            if let idx = self.idxForItem(with: item.id) {
                self.currentItems.remove(at: idx)
            }
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
    }
    
    /// Only public by design, if you need to override this method override `_prepare(forCollectionViewUpdates:)`
    override public func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        // In Xcode 12.5 it is impossible to use own `updateItems` - our solution with `UICollectionViewUpdateItem` subclass stopped working
        // (Apple is probably checking some private API and our customized getters are not called),
        // so instead of testing `prepare(forCollectionViewUpdates:)` we will test our custom function
        _prepare(forCollectionViewUpdates: updateItems)
        super.prepare(forCollectionViewUpdates: updateItems)
    }

    override open func finalizeCollectionViewUpdates() {
        appearingItems.removeAll()
        disappearingItems.removeAll()
        animatingAttributes.removeAll()
        super.finalizeCollectionViewUpdates()
        restoreOffset = nil
    }
    
    override open func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard let collectionView = self.collectionView else { return proposedContentOffset }
        // if we have any content offset to restore and if the collection view has enough items to scroll, restore it
        if let restore = restoreOffset,
           collectionView.contentSize.height > collectionView.bounds.height,
           !didPerformInitialScrollToBottom {
            didPerformInitialScrollToBottom = true
            return CGPoint(x: 0, y: collectionViewContentSize.height - restore)
        }
        return proposedContentOffset
    }

    // MARK: - Main layout access

    override open func prepare() {
        super.prepare()

        guard !didPerformInitialLayout else { return }
        didPerformInitialLayout = true

        guard currentItems.isEmpty else { return }
        guard let cv = collectionView else { return }
        currentCollectionViewWidth = cv.bounds.width

        let count = cv.numberOfItems(inSection: 0)
        guard count > 0 else { return }

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

    override open func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let idx = itemIndexPath.item
        if appearingItems.contains(itemIndexPath) {
            // this is item that have been inserted into collection view in current batch update
            let attribute = currentItems[idx]
                .attribute(for: idx, width: currentCollectionViewWidth)
                .copy() as! UICollectionViewLayoutAttributes
            
            animatingAttributes[itemIndexPath] = attribute
            return attribute
        } else {
            // this is item that already presented in collection view, but collection view decided to reload it
            // by removing and inserting it back (4head)
            // to properly animate possible change of such item, we need to return its attributes BEFORE batch update
            guard let id = idForItem(at: idx) else { return nil }
            return oldIdxForItem(with: id).map { oldIdx in
                let attr = previousItems[oldIdx]
                    .attribute(for: oldIdx, width: currentCollectionViewWidth)
                    .copy() as! UICollectionViewLayoutAttributes
                
                attr.alpha = 0
                return attr
            }
        }
    }

    override open func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let idx = itemIndexPath.item
        guard let id = oldIdForItem(at: idx) else { return nil }
        if disappearingItems.contains(itemIndexPath) {
            // item gets removed from collection view, we don't do any special delete animations for now, so just return
            // item attributes BEFORE batch update and let it fade away
            let attribute = previousItems[idx]
                .attribute(for: idx, width: currentCollectionViewWidth)
                .copy() as! UICollectionViewLayoutAttributes
            
            attribute.alpha = 0
            return attribute
            
        } else if let newIdx = idxForItem(with: id) {
            // this is item that will stay in collection view, but collection view decided to reload it
            // by removing and inserting it back (4head)
            // to properly animate possible change of such item, we need to return its attributes AFTER batch update
            let attribute = currentItems[newIdx]
                .attribute(for: newIdx, width: currentCollectionViewWidth)
                .copy() as! UICollectionViewLayoutAttributes
            
            animatingAttributes[attribute.indexPath] = attribute
            attribute.alpha = 0
            return attribute
        }

        return super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
    }

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
