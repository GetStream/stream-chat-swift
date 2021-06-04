
Custom Table View like layout that position item at index path 0-0 on bottom of the list.

``` swift
open class ChatMessageListCollectionViewLayout: UICollectionViewLayout 
```

Unlike `UICollectionViewFlowLayout` we ignore some invalidation calls and persist items attributes between updates.
This resolves problem when on item reload layout would change content offset and user ends up on completely different item.
Layout intended for batch updates and right now I have no idea how it will react to `collectionView.reloadData()`.

## Inheritance

`UICollectionViewLayout`

## Initializers

### `init()`

``` swift
override public required init() 
```

### `init?(coder:)`

``` swift
public required init?(coder: NSCoder) 
```

## Properties

### `previousItems`

Layout items before currently running batch update

``` swift
open var previousItems: [LayoutItem] = []
```

### `currentItems`

Actual layout

``` swift
open var currentItems: [LayoutItem] = []
```

### `estimatedItemHeight`

With better approximation you are getting better performance

``` swift
open var estimatedItemHeight: CGFloat = 200
```

### `spacing`

Vertical spacing between items

``` swift
open var spacing: CGFloat = 2
```

### `appearingItems`

Items that have been added to collectionview during currently running batch updates

``` swift
open var appearingItems: Set<IndexPath> = []
```

### `disappearingItems`

Items that have been removed from collectionview during currently running batch updates

``` swift
open var disappearingItems: Set<IndexPath> = []
```

### `animatingAttributes`

We need to cache attributes used for initial/final state of added/removed items to update them after AutoLayout pass.
This will prevent items to appear with `estimatedItemHeight` and animating to real size

``` swift
open var animatingAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
```

### `collectionViewContentSize`

``` swift
override open var collectionViewContentSize: CGSize 
```

### `currentCollectionViewWidth`

``` swift
open var currentCollectionViewWidth: CGFloat = 0
```

### `preBatchUpdatesCall`

Used to prevent layout issues during batch updates.

``` swift
open var preBatchUpdatesCall = false
```

Before batch updates collection view says to invalidate layout with `invalidateDataSourceCounts`.
Next it ask us for attributes for new items before says which items are new. So we have no way to properly calculate it.
`UICollectionViewFlowLayout` uses private API to get this info. We are don not have such privilege.
If we return wrong attributes user will see artifacts and broken layout during batch update animation.
By not returning any attributes during batch updates we are able to prevent such artifacts.

## Methods

### `invalidateLayout(with:)`

``` swift
override open func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) 
```

### `shouldInvalidateLayout(forPreferredLayoutAttributes:withOriginalAttributes:)`

``` swift
override open func shouldInvalidateLayout(
        forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
        withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes
    ) -> Bool 
```

### `invalidationContext(forPreferredLayoutAttributes:withOriginalAttributes:)`

``` swift
override open func invalidationContext(
        forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
        withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutInvalidationContext 
```

### `shouldInvalidateLayout(forBoundsChange:)`

``` swift
override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool 
```

### `invalidationContext(forBoundsChange:)`

``` swift
override open func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext 
```

### `_prepare(forCollectionViewUpdates:)`

``` swift
open func _prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) 
```

### `prepare(forCollectionViewUpdates:)`

Only public by design, if you need to override this method override `_prepare(forCollectionViewUpdates:​)`

``` swift
override public func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) 
```

### `finalizeCollectionViewUpdates()`

``` swift
override open func finalizeCollectionViewUpdates() 
```

### `targetContentOffset(forProposedContentOffset:)`

``` swift
override open func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint 
```

### `prepare()`

``` swift
override open func prepare() 
```

### `layoutAttributesForElements(in:)`

``` swift
override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? 
```

### `layoutAttributesForItem(at:)`

``` swift
override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? 
```

### `initialLayoutAttributesForAppearingItem(at:)`

``` swift
override open func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? 
```

### `finalLayoutAttributesForDisappearingItem(at:)`

``` swift
override open func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? 
```

### `idForItem(at:)`

``` swift
open func idForItem(at idx: Int) -> UUID? 
```

### `idxForItem(with:)`

``` swift
open func idxForItem(with id: UUID) -> Int? 
```

### `oldIdForItem(at:)`

``` swift
open func oldIdForItem(at idx: Int) -> UUID? 
```

### `oldIdxForItem(with:)`

``` swift
open func oldIdxForItem(with id: UUID) -> Int? 
```
