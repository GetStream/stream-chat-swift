
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

### `setUpAppearance()`

``` swift
open func setUpAppearance() 
```

### `setUpLayout()`

``` swift
open func setUpLayout() 
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
    ) -> _ChatMessageCell<ExtraData> 
```

#### Parameters

  - contentViewClass: The type of content view the cell will be displaying.
  - layoutOptions: The option set describing content view layout.
  - indexPath: The cell index path.

#### Returns

The instance of `_ChatMessageCollectionViewCell<ExtraData>` set up with the provided `contentViewClass` and `layoutOptions`

### `scrollStateChanged(_:)`

Is invoked when a pan gesture state is changed.

``` swift
@objc
    open func scrollStateChanged(_ sender: UIPanGestureRecognizer) 
```

### `setOverlayViewAlpha(_:animated:)`

Updates the alpha of the overlay.

``` swift
open func setOverlayViewAlpha(_ alpha: CGFloat, animated: Bool = true) 
```

### `scrollToMostRecentMessage(animated:)`

Scrolls to most recent message

``` swift
open func scrollToMostRecentMessage(animated: Bool = true) 
```

### `updateMessages(with:completion:)`

Updates the table view data with given `changes`.

``` swift
open func updateMessages(
        with changes: [ListChange<_ChatMessage<ExtraData>>],
        completion: (() -> Void)? = nil
    ) 
