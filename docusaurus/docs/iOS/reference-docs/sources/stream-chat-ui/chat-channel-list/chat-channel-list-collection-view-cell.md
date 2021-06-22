---
title: ChatChannelListCollectionViewCell
---

A `UICollectionViewCell` subclass that shows channel information.

``` swift
open class _ChatChannelListCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell,
    ThemeProvider 
```

## Inheritance

[`_CollectionViewCell`](../common-views/_collection-view-cell), [`ThemeProvider`](../utils/theme-provider)

## Properties

### `itemView`

The `ChatChannelListItemView` instance used as content view.

``` swift
open private(set) lazy var itemView: _ChatChannelListItemView<ExtraData> = components
        .channelContentView
        .init()
        .withoutAutoresizingMaskConstraints
```

### `swipeableView`

The `SwipeableView` instance which is used for revealing buttons when cell is swiped.

``` swift
open private(set) lazy var swipeableView: _SwipeableView<ExtraData> = components
        .channelActionsView.init()
        .withoutAutoresizingMaskConstraints
```

### `isHighlighted`

``` swift
override open var isHighlighted: Bool 
```

## Methods

### `prepareForReuse()`

``` swift
override public func prepareForReuse() 
```

### `setUp()`

``` swift
override open func setUp() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `preferredLayoutAttributesFitting(_:)`

``` swift
override open func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes 
```
