
The collection view that provides convenient API for dequeuing `_СhatMessageCollectionViewCell` instances
with the provided content view type and layout options.

``` swift
open class ChatMessageListCollectionView<ExtraData: ExtraDataTypes>: UICollectionView, Customizable, ComponentsProvider 
```

## Inheritance

[`Customizable`](../CommonViews/Customizable), [`ComponentsProvider`](../Utils/ComponentsProvider), `UICollectionView`

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

### `needsToScrollToMostRecentMessage`

``` swift
open var needsToScrollToMostRecentMessage = false
```

### `needsToScrollToMostRecentMessageAnimated`

``` swift
open var needsToScrollToMostRecentMessageAnimated = false
```

### `scrollOverlayView`

View used to display date of currently displayed messages

``` swift
open lazy var scrollOverlayView: ChatMessageListScrollOverlayView 
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
open func dequeueReusableCell<ExtraData: ExtraDataTypes>(
        contentViewClass: _ChatMessageContentView<ExtraData>.Type,
        attachmentViewInjectorType: _AttachmentViewInjector<ExtraData>.Type?,
        layoutOptions: ChatMessageLayoutOptions,
        for indexPath: IndexPath
    ) -> _СhatMessageCollectionViewCell<ExtraData> 
```

#### Parameters

  - contentViewClass: The type of content view the cell will be displaying.
  - layoutOptions: The option set describing content view layout.
  - indexPath: The cell index path.

#### Returns

The instance of `_СhatMessageCollectionViewCell<ExtraData>` set up with the provided `contentViewClass` and `layoutOptions`

### `updateMessages(with:completion:)`

Updates the collection view data with given `changes`.

``` swift
open func updateMessages<ExtraData: ExtraDataTypes>(
        with changes: [ListChange<_ChatMessage<ExtraData>>],
        completion: ((Bool) -> Void)? = nil
    ) 
```

### `setNeedsScrollToMostRecentMessage(animated:)`

Will scroll to most recent message on next `updateMessages` call

``` swift
open func setNeedsScrollToMostRecentMessage(animated: Bool = true) 
```

### `scrollToMostRecentMessageIfNeeded()`

Force scroll to most recent message check without waiting for `updateMessages`

``` swift
open func scrollToMostRecentMessageIfNeeded() 
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
