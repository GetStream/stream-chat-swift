
### `unreadCountView`

The view showing number of unread messages in channel if any.

``` swift
open private(set) lazy var unreadCountView: _ChatMessageListUnreadCountView<ExtraData> = components
        .messageListUnreadCountView
        .init()
        .withoutAutoresizingMaskConstraints
```

## Methods

### `layoutSubviews()`

``` swift
override open func layoutSubviews() 
```

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
