
### `content`

The displayed content.

``` swift
open var content: String? 
```

### `textLabel`

The view used to display the content.

``` swift
open private(set) lazy var textLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withoutAutoresizingMaskConstraints
```

### `dataSource`

The data source used to get the content to display.

``` swift
public weak var dataSource: ChatMessageListScrollOverlayDataSource?
```

### `listView`

The list view that is listened for being scrolled.

``` swift
public weak var listView: UITableView? 
```

## Methods

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```

### `layoutSubviews()`

``` swift
override open func layoutSubviews() 
```

### `scrollStateChanged(_:)`

Is invoked when a pan gesture state is changed.

``` swift
@objc
    open func scrollStateChanged(_ sender: UIPanGestureRecognizer) 
```

### `setAlpha(_:)`

Updates the alpha of the overlay.

``` swift
open func setAlpha(_ alpha: CGFloat) 
