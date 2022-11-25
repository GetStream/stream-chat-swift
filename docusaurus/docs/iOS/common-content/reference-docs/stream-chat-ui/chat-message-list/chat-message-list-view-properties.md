
### `isLastCellFullyVisible`

A Boolean that returns true if the bottom cell is fully visible.
Which is also means that the collection view is fully scrolled to the boom.

``` swift
open var isLastCellFullyVisible: Bool 
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

### `reuseIdentifier(contentViewClass:attachmentViewInjectorType:layoutOptions:)`

Calculates the cell reuse identifier for the given options.

``` swift
open func reuseIdentifier(
        contentViewClass: ChatMessageContentView.Type,
        attachmentViewInjectorType: AttachmentViewInjector.Type?,
        layoutOptions: ChatMessageLayoutOptions
    ) -> String 
```

#### Parameters

  - `contentViewClass`: The type of message content view.
  - `attachmentViewInjectorType`: The type of attachment injector.
  - `layoutOptions`: The message content view layout options.

#### Returns

The cell reuse identifier.

### `reuseIdentifier(for:)`

Returns the reuse identifier of the given cell.

``` swift
open func reuseIdentifier(for cell: ChatMessageCell?) -> String? 
```

#### Parameters

  - `cell`: The cell to calculate reuse identifier for.

#### Returns

The reuse identifier.

### `dequeueReusableCell(contentViewClass:attachmentViewInjectorType:layoutOptions:for:)`

Dequeues the message cell. Registers the cell for received combination of `contentViewClass + layoutOptions`
if needed.

``` swift
open func dequeueReusableCell(
        contentViewClass: ChatMessageContentView.Type,
        attachmentViewInjectorType: AttachmentViewInjector.Type?,
        layoutOptions: ChatMessageLayoutOptions,
        for indexPath: IndexPath
    ) -> ChatMessageCell 
```

#### Parameters

  - `contentViewClass`: The type of content view the cell will be displaying.
  - `layoutOptions`: The option set describing content view layout.
  - `indexPath`: The cell index path.

#### Returns

The instance of `ChatMessageCollectionViewCell` set up with the provided `contentViewClass` and `layoutOptions`

### `scrollToMostRecentMessage(animated:)`

Scrolls to most recent message

``` swift
open func scrollToMostRecentMessage(animated: Bool = true) 
```

### `updateMessages(with:completion:)`

Updates the table view data with given `changes`.

``` swift
open func updateMessages(
        with changes: [ListChange<ChatMessage>],
        completion: (() -> Void)? = nil
    ) 
```

### `reloadRows(at:with:)`

``` swift
override open func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) 
