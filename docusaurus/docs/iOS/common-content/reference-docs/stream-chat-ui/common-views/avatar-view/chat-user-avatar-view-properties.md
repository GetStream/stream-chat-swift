
### `presenceAvatarView`

A view that shows the avatar image and online presence indicator.

``` swift
open private(set) lazy var presenceAvatarView: ChatPresenceAvatarView = components
        .presenceAvatarView.init()
        .withoutAutoresizingMaskConstraints
```

### `content`

The data this view component shows.

``` swift
open var content: ChatUser? 
```

## Methods

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
