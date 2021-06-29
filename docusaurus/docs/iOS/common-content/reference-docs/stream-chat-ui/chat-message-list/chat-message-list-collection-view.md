---
title: ChatMessageListCollectionView
---

The collection view that provides convenient API for dequeuing `_ChatMessageCollectionViewCell` instances
with the provided content view type and layout options.

``` swift
open class ChatMessageListCollectionView<ExtraData: ExtraDataTypes>: UICollectionView, Customizable, ComponentsProvider 
```

## Inheritance

[`Customizable`](../../common-views/customizable), [`ComponentsProvider`](../../utils/components-provider), `UICollectionView`

## Initializers

### `init(layout:)`

``` swift
public required init(layout: ChatMessageListCollectionViewLayout) 
```

### `init?(coder:)`

``` swift
public required init?(coder: NSCoder) 
```

## Properties

### `scrollOverlayView`

View used to display date of currently displayed messages

``` swift
open lazy var scrollOverlayView: ChatMessageListScrollOverlayView 
```

### `isLastCellFullyVisible`

A Boolean that returns true if the bottom cell is fully visible.
Which is also means that the collection view is fully scrolled to the boom.

``` swift
open var isLastCellFullyVisible: Bool 
```

### `isLastCellVisible`

A Boolean that returns true if the last cell is visible, but can be just partially visible.

``` swift
open var isLastCellVisible: Bool 
```

## Methods

### `didMoveToSuperview()`

``` swift
override open func didMoveToSuperview() 
```

### `setUp()`

``` swift
open func setUp() 
```

### `scrollStateChanged(_:)`

``` swift
@objc
    open func scrollStateChanged(_ sender: UIPanGestureRecognizer) 
```

### `setUpLayout()`

``` swift
open func setUpLayout() 
```

### `setUpAppearance()`

``` swift
open func setUpAppearance() 
```

### `updateContent()`

``` swift
open func updateContent() 
```

### `dequeueReusableCell(contentViewClass:attachmentViewInjectorType:layoutOptions:for:)`

Dequeues the message cell. Registers the cell for received combination of `contentViewClass + layoutOptions`
if needed.

``` swift
open func dequeueReusableCell(
        contentViewClass: _ChatMessageContentView<ExtraData>.Type,
        attachmentViewInjectorType: _AttachmentViewInjector<ExtraData>.Type?,
        layoutOptions: ChatMessageLayoutOptions,
        for indexPath: IndexPath
    ) -> _ChatMessageCollectionViewCell<ExtraData> 
```

#### Parameters

  - contentViewClass: The type of content view the cell will be displaying.
  - layoutOptions: The option set describing content view layout.
  - indexPath: The cell index path.

#### Returns

The instance of `_ChatMessageCollectionViewCell<ExtraData>` set up with the provided `contentViewClass` and `layoutOptions`

### `updateMessages(with:completion:)`

Updates the collection view data with given `changes`.

``` swift
open func updateMessages(
        with changes: [ListChange<_ChatMessage<ExtraData>>],
        completion: ((Bool) -> Void)? = nil
    ) 
```

### `scrollToMostRecentMessage(animated:)`

Scrolls to most recent message

``` swift
open func scrollToMostRecentMessage(animated: Bool = true) 
```

### `traitCollectionDidChange(_:)`

``` swift
override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) 
```

### `setOverlayViewAlpha(_:animated:)`

``` swift
open func setOverlayViewAlpha(_ alpha: CGFloat, animated: Bool = true) 
```
